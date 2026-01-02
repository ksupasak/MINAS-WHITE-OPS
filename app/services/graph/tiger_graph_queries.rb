module Graph
  class TigerGraphQueries
    def initialize(customer:)
      @customer = customer
      @client = Graph::TigerGraphClient.new(
        host: ENV.fetch("TIGERGRAPH_HOST", "http://tigergraph:14240"),
        graph: ENV.fetch("TIGERGRAPH_GRAPH", "social"),
        secret: ENV.fetch("TIGERGRAPH_SECRET", "")
      )
    end

    def subject_graph(subject_id:, from: nil, to: nil, limit: 200)
      return { nodes: [], edges: [] } unless subject_id && @customer
      payload = @client.get("subjectGraph", {
        subject_id: subject_id.to_s,
        customer_id: @customer.id.to_s,
        from: from&.iso8601,
        to: to&.iso8601,
        limit: limit
      })
      normalize_graph(payload)
    rescue StandardError => e
      Rails.logger.error("TigerGraph subject_graph failed: #{e.message}")
      { nodes: [], edges: [] }
    end

    def top_hashtags(subject_id:, limit: 20)
      payload = @client.get("topHashtags", {
        subject_id: subject_id&.to_s,
        customer_id: @customer&.id&.to_s,
        limit: limit
      })
      (payload["results"] || []).map do |row|
        { tag: row["tag"], count: row["count"].to_i }
      end
    rescue StandardError => e
      Rails.logger.error("TigerGraph top_hashtags failed: #{e.message}")
      []
    end

    def top_users(subject_id:, limit: 20)
      payload = @client.get("topUsers", {
        subject_id: subject_id&.to_s,
        customer_id: @customer&.id&.to_s,
        limit: limit
      })
      (payload["results"] || []).map do |row|
        { user_id: row["user_id"], username: row["username"], count: row["count"].to_i }
      end
    rescue StandardError => e
      Rails.logger.error("TigerGraph top_users failed: #{e.message}")
      []
    end

    private

    def normalize_graph(payload)
      data = payload["results"]&.first || payload
      nodes = (data["nodes"] || []).map do |n|
        { id: n["id"], label: n["label"] || n["id"], type: n["type"] }
      end
      edges = (data["edges"] || []).map do |e|
        { id: e["id"], source: e["source"], target: e["target"], label: e["label"] }
      end
      { nodes: nodes, edges: edges }
    end
  end
end
