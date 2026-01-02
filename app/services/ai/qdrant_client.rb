require "net/http"
require "json"
require "securerandom"

module Ai
  class QdrantClient
    VECTOR_SIZE = 1536  # nomic-embed-text default size

    def initialize(url: ENV.fetch("QDRANT_URL", "http://localhost:6333"), collection: ENV.fetch("QDRANT_COLLECTION", "posts"))
      @url = url
      @collection = collection
    end

    def ensure_collection!
      uri = URI.parse("#{@url}/collections/#{@collection}")
      res = http(uri).request(Net::HTTP::Get.new(uri))
      puts "Qdrant ensure collection response: #{res.inspect}"
      return if res.is_a?(Net::HTTPSuccess)
      puts "Qdrant ensure collection response:2  #{res.inspect}"
      create_payload = {
        vectors: {
          size: VECTOR_SIZE,
          distance: "Cosine"
        }
      }
      req = Net::HTTP::Put.new(uri, { "Content-Type" => "application/json" })
      req.body = create_payload.to_json
      create_res = http(uri).request(req)
      Rails.logger.info("Created Qdrant collection: #{@collection}")
      raise "Failed to create Qdrant collection: #{create_res.code} - #{create_res.body}" unless create_res.is_a?(Net::HTTPSuccess)
    end

    def upsert(point_id:, vector:, payload: {})
   
      return false if vector.blank?
      
      uri = URI.parse("#{@url}/collections/#{@collection}/points?wait=true")
      puts "Qdrant upsert URI: #{uri.inspect}"
      req = Net::HTTP::Put.new(uri, { "Content-Type" => "application/json" })
      
      # Convert ObjectId to UUID-compatible format for Qdrant
      uuid_id = to_uuid(point_id)
      
      req.body = { 
        points: [{ 
          id: uuid_id, 
          vector: vector, 
          payload: payload.merge(original_id: point_id.to_s)
        }] 
      }.to_json
      puts "Qdrant upsert request: #{req.body}"
      res = http(uri).request(req)

      puts "Qdrant upsert response: #{res.inspect}"
      
      unless res.is_a?(Net::HTTPSuccess)
        Rails.logger.error("Qdrant upsert failed: #{res.code} - #{res.body}")
        raise "Qdrant upsert failed #{res.code}"
      end
      true
    end

    def search(vector:, top_k: 10, filter: nil, with_payload: true)
      return [] if vector.blank?
      
      uri = URI.parse("#{@url}/collections/#{@collection}/points/search")
      req = Net::HTTP::Post.new(uri, { "Content-Type" => "application/json" })
      
      body = { 
        vector: vector, 
        limit: top_k,
        with_payload: with_payload
      }
      body[:filter] = filter if filter
      req.body = body.to_json
      
      res = http(uri).request(req)
      return [] unless res.is_a?(Net::HTTPSuccess)
      
      parsed = JSON.parse(res.body)
      results = parsed.dig("result") || []
      
      # Map back original_id to post_id in payload
      results.map do |r|
        if r["payload"] && r["payload"]["original_id"]
          r["payload"]["post_id"] = r["payload"]["original_id"]
        end
        r
      end
    rescue StandardError => e
      Rails.logger.error("Qdrant search error: #{e.message}")
      Rails.logger.error(e.backtrace.first(3).join("\n"))
      []
    end

    def delete(point_id:)
      uuid_id = to_uuid(point_id)
      uri = URI.parse("#{@url}/collections/#{@collection}/points/delete")
      req = Net::HTTP::Post.new(uri, { "Content-Type" => "application/json" })
      req.body = { points: [uuid_id] }.to_json
      res = http(uri).request(req)
      res.is_a?(Net::HTTPSuccess)
    end

    def collection_info
      uri = URI.parse("#{@url}/collections/#{@collection}")
      res = http(uri).request(Net::HTTP::Get.new(uri))
      return nil unless res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body)
    rescue StandardError => e
      Rails.logger.error("Qdrant collection info error: #{e.message}")
      nil
    end

    private

    def http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 30
      http
    end

    # Convert MongoDB ObjectId to UUID format for Qdrant
    def to_uuid(id)
      id_str = id.to_s
      # Pad or hash to create valid UUID
      if id_str.length == 24  # MongoDB ObjectId
        # Create deterministic UUID from ObjectId
        hex = id_str.ljust(32, '0')
        "#{hex[0,8]}-#{hex[8,4]}-#{hex[12,4]}-#{hex[16,4]}-#{hex[20,12]}"
      else
        # Already a UUID or generate one
        id_str =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i ? id_str : SecureRandom.uuid
      end
    end
  end
end
