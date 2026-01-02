module Ai
  class NotebookService
    MAX_CANDIDATES = 500

    def initialize(embedding_client: EmbeddingClient.new, chat_service: ChatService.new, qdrant_client: nil)
      @embedding_client = embedding_client
      @chat_service = chat_service
      @qdrant_client = qdrant_client || Ai::QdrantClient.new
    end

    def index_post(customer_id:, subject_id:, post_id:, text:)
      embedding = @embedding_client.embed(text.to_s)

      # Always index to Qdrant
      r = @qdrant_client.ensure_collection!
      puts "Qdrant ensure collection result: #{r}"
      r = @qdrant_client.upsert(
        point_id: post_id.to_s,
        vector: embedding,
        payload: { 
          customer_id: customer_id.to_s, 
          subject_id: subject_id.to_s, 
          post_id: post_id.to_s, 
          text: text.to_s.truncate(1000)
        }
      )

      puts "Qdrant upsert result: #{r}"

      # Also save to NotebookEntry for backup
      entry = NotebookEntry.where(customer_id: customer_id, post_id: post_id).first_or_initialize
      entry.subject_id = subject_id
      entry.text = text
      entry.embedding = embedding
      entry.save!

      entry
    end

    def query(customer_id:, question:, top_k: 10)
      embedding = @embedding_client.embed(question.to_s)
      return { answer: "", sources: [], posts: [] } if embedding.blank?

      # Search from Qdrant
      search_results = qdrant_vector_search(customer_id: customer_id, embedding: embedding, top_k: top_k)
      
      # Build sources from Qdrant results
      sources = search_results[:sources]
      posts = search_results[:posts]
      
      # Generate AI answer based on context
      prompt = build_prompt(question: question, sources: sources)
      answer = @chat_service.generate(prompt)
      
      { answer: answer, sources: sources, posts: posts }
    end

    # Direct search without AI answer
    def search_posts(customer_id:, query:, top_k: 10)
      embedding = @embedding_client.embed(query.to_s)
      return { sources: [], posts: [] } if embedding.blank?
      
      qdrant_vector_search(customer_id: customer_id, embedding: embedding, top_k: top_k)
    end

    private

    def qdrant_vector_search(customer_id:, embedding:, top_k:)
      @qdrant_client.ensure_collection!
      
      filter = { must: [{ key: "customer_id", match: { value: customer_id.to_s } }] }
      results = @qdrant_client.search(vector: embedding, top_k: top_k, filter: filter)
      
      # Extract post_ids and scores from Qdrant results
      post_data = results.map do |r|
        {
          post_id: r.dig("payload", "post_id") || r.dig("id"),
          subject_id: r.dig("payload", "subject_id"),
          text: r.dig("payload", "text"),
          score: r["score"]
        }
      end.compact
      
      # Fetch actual Post objects
      post_ids = post_data.map { |d| d[:post_id] }.compact.uniq
      posts = Post.where(:_id.in => post_ids.map { |id| BSON::ObjectId(id) rescue id }).to_a
      posts_by_id = posts.index_by { |p| p.id.to_s }
      
      # Build sources with scores and post data
      sources = post_data.map do |data|
        post = posts_by_id[data[:post_id]]
        {
          post_id: data[:post_id],
          subject_id: data[:subject_id],
          snippet: data[:text]&.truncate(300) || post&.text&.truncate(300),
          score: data[:score],
          title: post&.title,
          source: post&.source,
          subject: post&.subject
        }
      end
      
      { sources: sources, posts: posts }
    rescue StandardError => e
      Rails.logger.error("Qdrant vector search failed: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      # Fallback to in-memory search
      fallback_search(customer_id: customer_id, embedding: embedding, top_k: top_k)
    end

    def fallback_search(customer_id:, embedding:, top_k:)
      entries = NotebookEntry.where(customer_id: customer_id).order_by(created_at: :desc).limit(MAX_CANDIDATES).to_a
      scored = entries.map do |entry|
        next if entry.embedding.blank?
        sim = cosine_similarity(embedding, entry.embedding)
        [entry, sim]
      end.compact
      
      top_entries = scored.sort_by { |(_, sim)| -sim }.first(top_k)
      
      post_ids = top_entries.map { |(e, _)| e.post_id }.compact
      posts = Post.where(:_id.in => post_ids).to_a
      posts_by_id = posts.index_by { |p| p.id.to_s }
      
      sources = top_entries.map do |(entry, score)|
        post = posts_by_id[entry.post_id.to_s]
        {
          post_id: entry.post_id,
          subject_id: entry.subject_id&.to_s,
          snippet: entry.text&.truncate(300),
          score: score,
          title: post&.title,
          source: post&.source,
          subject: post&.subject
        }
      end
      
      { sources: sources, posts: posts }
    end

    def cosine_similarity(a, b)
      return 0.0 if a.empty? || b.empty? || a.length != b.length
      dot = a.zip(b).sum { |x, y| x.to_f * y.to_f }
      norm_a = Math.sqrt(a.sum { |x| x.to_f * x.to_f })
      norm_b = Math.sqrt(b.sum { |y| y.to_f * y.to_f })
      return 0.0 if norm_a.zero? || norm_b.zero?
      dot / (norm_a * norm_b)
    end

    def build_prompt(question:, sources:)
      context = sources.map.with_index(1) do |s, idx|
        title = s[:title] || "Post"
        text = s[:snippet] || ""
        score = s[:score] ? "(score: #{(s[:score] * 100).round(1)}%)" : ""
        "[#{idx}] #{title} #{score}\n#{text}\n"
      end.join("\n")

      <<~PROMPT
      You are a helpful assistant for Social Monitor. Use the context from indexed posts to answer.
      If the context is insufficient, say you don't have enough data.
      Answer in the same language as the question.

      Context from indexed posts:
      #{context}

      Question: #{question}
      Answer:
      PROMPT
    end
  end
end
