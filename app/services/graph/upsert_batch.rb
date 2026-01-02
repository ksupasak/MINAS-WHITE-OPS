require "securerandom"

module Graph
  class UpsertBatch
    def initialize(customer:, feeder:, items: [])
      @customer = customer
      @feeder = feeder
      @items = items
      @database = @customer.slug
    end

    def call
      return if @items.empty?

      session = Graph::Client.session(database: @database)

      session.write_transaction do |tx|
        @items.each do |item|
          puts
          puts 
          puts item.to_json
          upsert_post(tx, item)
          link_reference(tx, item)
          link_hashtags(tx, item)
        end
      end
      session.close if session.respond_to?(:close)

      SecureRandom.uuid
    end

    private

    # MERGE (u:Source {source_id: $source_id})
    # ON CREATE SET u.source_id = $source_id, u.name = $source, u.channel = $channel, u.channel_id = $channel_id
    # ON MATCH SET u.username = $username

    def upsert_post(tx, item)
      params = base_params(item)
  
      tx.run(<<~CYPHER, **params)
        MERGE (u:Source {source_id: $source_id})
        ON CREATE SET u.id= $source, u.display_name = $source, u.name = $source, u.channel = $channel, u.channel_id = $channel_id
        ON MATCH SET u.id= $source, u.display_name = $source, u.name = $source, u.channel = $channel, u.channel_id = $channel_id

        MERGE (c:Channel {name: $channel})
        ON CREATE SET c.name = $channel

        MERGE (s:Subject {name: $subject})
        ON CREATE SET s.name = $subject

        MERGE (r:Regional {name: $regional})
        ON CREATE SET r.name = $regional

        MERGE (p:Post {post_id: $post_id})
        ON CREATE SET p.id= $post_id, p.name = $title, p.channel = $channel, p.channel_id = $channel_id, p.text = $text, p.created_at = datetime($created_at),
            p.ref_type = $ref_type, p.link = $link, p.regional = $regional,p.snippet = $snippet
        ON MATCH SET p.id= $post_id, p.name = $title, p.channel = $channel, p.channel_id = $channel_id, p.text = $text, p.created_at = datetime($created_at),
            p.ref_type = $ref_type, p.link = $link, p.regional = $regional,p.snippet = $snippet
       

        MERGE (u)-[:POSTED]->(p)
        MERGE (p)-[:IN_CHANNEL]->(c)
        MERGE (p)-[:IN_SUBJECT]->(s)
        MERGE (p)-[:IN_REGIONAL]->(r)
      CYPHER
    end

    def link_reference(tx, item)
      return unless item[:ref_post_id].present?

      params = base_params(item)
      tx.run(<<~CYPHER, **params)
        MATCH (p:Post {post_id: $post_id})
        MERGE (r:Post {post_id: $ref_post_id})
        MERGE (p)-[rel:REFERS_TO {ref_type: $ref_type}]->(r)
        RETURN rel
      CYPHER
    end

    def link_hashtags(tx, item)
      Array(item[:hashtags]).each do |tag|
        params = base_params(item).merge(tag: tag)
        tx.run(<<~CYPHER, **params)
          MATCH (p:Post {post_id: $post_id})
          MERGE (h:HashTag {tag: $tag})
          MERGE (p)-[:HAS_TAG]->(h)
        CYPHER
      end
    end

    def base_params(item)
        regional = item[:regional] || "th"
      {
        post_id: item[:post_id].to_s,
        title: item[:raw][:title],
        source: item[:source],
        source_id: item[:source_id].to_s,
        subject: item[:subject],
        subject_id: item[:subject_id].to_s,
        snippet: item[:snippet],
        channel: item[:channel],
        channel_id: item[:channel_id].to_s,
        text: item[:text],
        created_at: (item[:created_at] || Time.current).iso8601,
        link: item[:link],
        regional: regional,
        ref_type: item[:ref_type],
        ref_post_id: item[:ref_post_id],
        subject_ids: @subject_ids,
        project_id: item[:project_id].to_s,
        customer_id: item[:customer_id].to_s,
        hashtags: item[:hashtags]
      }
    end
  end
end
