require "net/http"
require "json"

module Graph
  class TigerGraphClient
    def initialize(host: nil, graph: nil, secret: nil)
      @host = host || ENV.fetch("TIGERGRAPH_HOST", "http://tigergraph:14240")
      @graph = graph || ENV.fetch("TIGERGRAPH_GRAPH", "social")
      @secret = secret || ENV.fetch("TIGERGRAPH_SECRET", "")
    end

    # GET request for queries
    def get(query_name, params = {})
      uri = URI.parse(File.join(@host, "/restpp/query/#{@graph}/#{query_name}"))
      uri.query = URI.encode_www_form(params.merge({ "token" => token }))
      response = Net::HTTP.get_response(uri)
      raise "TigerGraph HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    end

    # POST request for upsert vertices
    def upsert_vertices(vertex_type, vertices)
      uri = URI.parse(File.join(@host, "/restpp/graph/#{@graph}/vertices/#{vertex_type}"))
      post_json(uri, vertices)
    end

    # POST request for upsert edges
    def upsert_edges(source_type, edge_type, target_type, edges)
      uri = URI.parse(File.join(@host, "/restpp/graph/#{@graph}/edges/#{source_type}/#{edge_type}/#{target_type}"))
      post_json(uri, edges)
    end

    # POST request for batch upsert (vertices and edges together)
    def upsert(payload)
      uri = URI.parse(File.join(@host, "/restpp/graph/#{@graph}"))
      post_json(uri, payload)
    end

    # Check connection
    def ping
      uri = URI.parse(File.join(@host, "/api/ping"))
      response = Net::HTTP.get_response(uri)
      response.is_a?(Net::HTTPSuccess)
    rescue
      false
    end

    def graph_name
      @graph
    end

    def host
      @host
    end

    private

    def post_json(uri, payload)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{token}"
      request.body = payload.to_json

      response = http.request(request)
      raise "TigerGraph HTTP #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    end

    def token
      @token ||= begin
        uri = URI.parse(File.join(@host, "/requesttoken"))
        uri.query = URI.encode_www_form(secret: @secret)
        res = Net::HTTP.get_response(uri)
        raise "TigerGraph token error #{res.code}" unless res.is_a?(Net::HTTPSuccess)
        body = JSON.parse(res.body)
        body.dig("results", 0, "token") || body["token"] || raise("Token missing")
      end
    end
  end
end
