module Graph
  class Queries
    def initialize(customer:)
      @customer = customer
      @database = customer.slug
    end

    def subject_graph(subject_id:, from: nil, to: nil, limit: 200)
      return { nodes: [], edges: [] } unless subject_id && @customer

      return tiger_graph_queries.subject_graph(subject_id: subject_id, from: from, to: to, limit: limit) if tiger_graph_enabled?

      params = {
        subject_id: subject_id.to_s,
        from: from&.iso8601,
        to: to&.iso8601,
        limit: limit
      }

      cypher = <<~CYPHER
        MATCH (p:Post)
        WHERE $subject_id IN p.subject_ids
          AND ($from IS NULL OR p.created_at >= datetime($from))
          AND ($to IS NULL OR p.created_at <= datetime($to))
        OPTIONAL MATCH (p)<-[:POSTED]-(u:Source)
        OPTIONAL MATCH (p)-[:HAS_TAG]->(h:HashTag)
        OPTIONAL MATCH (p)-[:IN_CHANNEL]->(c:Channel)
        RETURN p, u, h, c LIMIT $limit
      CYPHER

      records = Graph::Client.query(database: @database, cypher: cypher, params: params)&.to_a || []
      build_graph(records)
    end

    def top_hashtags(subject_id:, limit: 20)
      return [] unless @customer

      cypher = <<~CYPHER
        MATCH (p:Post)-[:HAS_TAG]->(h:HashTag)
        WHERE ($subject_id IS NULL OR $subject_id IN p.subject_ids)
        RETURN h.tag as tag, count(*) as count
        ORDER BY count DESC
        LIMIT $limit
      CYPHER
      params = { subject_id: subject_id&.to_s, limit: limit }
      return tiger_graph_queries.top_hashtags(subject_id: subject_id, limit: limit) if tiger_graph_enabled?

      results = Graph::Client.query(database: @database, cypher: cypher, params: params) || []
      results.map { |r| { tag: r["tag"], count: r["count"].to_i } }
    end

    def top_users(subject_id:, limit: 20)
      return [] unless @customer

      cypher = <<~CYPHER
        MATCH (u:Source)-[:POSTED]->(p:Post)
        WHERE ($subject_id IS NULL OR $subject_id IN p.subject_ids)
        RETURN u.id as user_id, u.username as username, count(*) as count
        ORDER BY count DESC
        LIMIT $limit
      CYPHER
      return tiger_graph_queries.top_users(subject_id: subject_id, limit: limit) if tiger_graph_enabled?

      params = { subject_id: subject_id&.to_s, limit: limit }
      results = Graph::Client.query(database: @database, cypher: cypher, params: params) || []
      results.map do |r|
        { user_id: r["user_id"], username: r["username"], count: r["count"].to_i }
      end
    end

    private

    def build_graph(records)
      nodes = {}
      edges = []

      records.each do |record|
        post = record["p"]
        user = record["u"]
        hashtag = record["h"]
        channel = record["c"]

        if post
          post_id = post["post_id"]
          nodes["post-#{post_id}"] = { id: "post-#{post_id}", label: sanitize_label(post["text"] || "post"), type: "post" }
        end

        if user && post
          user_id = user["id"]
          post_id = post["post_id"]
          nodes["user-#{user_id}"] = { id: "user-#{user_id}", label: user["username"] || "user", type: "user" }
          edges << { id: "edge-user-#{user_id}-post-#{post_id}", source: "user-#{user_id}", target: "post-#{post_id}", label: "POSTED" }
        end

        if hashtag && post
          tag = hashtag["tag"]
          post_id = post["post_id"]
          nodes["tag-#{tag}"] = { id: "tag-#{tag}", label: "##{tag}", type: "tag" }
          edges << { id: "edge-post-#{post_id}-tag-#{tag}", source: "post-#{post_id}", target: "tag-#{tag}", label: "HAS_TAG" }
        end

        if channel && post
          channel_name = channel["name"]
          post_id = post["post_id"]
          nodes["channel-#{channel_name}"] = { id: "channel-#{channel_name}", label: channel_name, type: "channel" }
          edges << { id: "edge-post-#{post_id}-channel-#{channel_name}", source: "post-#{post_id}", target: "channel-#{channel_name}", label: "IN_CHANNEL" }
        end
      end

      { nodes: nodes.values, edges: edges }
    end

    def sanitize_label(text)
      text.to_s[0, 60]
    end

    def tiger_graph_enabled?
      ENV["TIGERGRAPH_ENABLED"] == "true"
    end

    def tiger_graph_queries
      @tiger_graph_queries ||= Graph::TigerGraphQueries.new(customer: @customer)
    end
  end
end
