require "net/http"
require "json"

module Ai
  class EmbeddingClient
    def initialize(model: ENV.fetch("OLLAMA_MODEL", "qwen3-embedding:4b"), host: ENV.fetch("OLLAMA_HOST", "http://localhost:11434"))
      @model = model
      @host = host
    end

    def embed(text)
      uri = URI.parse(File.join(@host, "/api/embeddings"))
      payload = { model: @model, prompt: text }
      res = Net::HTTP.post(uri, payload.to_json, "Content-Type" => "application/json")
      return [] unless res.is_a?(Net::HTTPSuccess)
      body = JSON.parse(res.body)
      puts "EmbeddingClient Size response: #{body["embedding"].size} "
      body["embedding"] || []
    rescue StandardError => e
      Rails.logger.error("EmbeddingClient error: #{e.message}")
      []
    end
  end
end
