require "net/http"
require "json"

module Ai
  class SentimentService
    def initialize(model: ENV.fetch("OLLAMA_MODEL", "qwen3-embedding:4b"), host: ENV.fetch("OLLAMA_HOST", "http://localhost:11434"))
      @model = model
      @host = host
    end

    def analyze(text)
      uri = URI.parse(File.join(@host, "/api/generate"))
      payload = {
        model: @model,
        prompt: prompt_for(text),
        stream: false
      }
      res = Net::HTTP.post(uri, payload.to_json, "Content-Type" => "application/json")
      raise "Ollama error #{res.code}" unless res.is_a?(Net::HTTPSuccess)
      body = JSON.parse(res.body)
      result = parse_sentiment(body["response"])
      result[:model] = body["model"]
      result[:total_duration] = body["total_duration"]
      result[:load_duration] = body["load_duration"]
      result[:prompt_eval_count] = body["prompt_eval_count"]
      result[:prompt_eval_duration] = body["prompt_eval_duration"]
      result[:eval_count] = body["eval_count"]
      result[:eval_duration] = body["eval_duration"]
      result
      
    rescue StandardError => e
      Rails.logger.error("SentimentService error: #{e.message}")
      { sentiment: "unknown", confidence: nil, raw: nil }
    end

    private

    def prompt_for(text)
      <<~PROMPT
      You are a sentiment analyzer. Respond ONLY with one of: positive, negative, neutral. and confidence score between 0 and 1. In json format.
      {
        "sentiment": "positive",
        "confidence": 0.95,
        "reasoning": "reasoning for the sentiment"
      }
      {
        "sentiment": "negative",
        "confidence": 0.05,
        "reasoning": "reasoning for the sentiment"
      }
      {
        "sentiment": "neutral",
        "confidence": 0.5,
        "reasoning": "reasoning for the sentiment"
      } for example. you can add any another matrix for sentiment analysis in the result
      Text: #{text}
      PROMPT
    end

    def parse_sentiment(response)
      puts "RESPONSE: #{response}"
#       {
#   "sentiment": "neutral",
#   "confidence": 0.5
# }   

      response = response.gsub("```json\n", "").gsub("\n```", "")

      res = JSON.parse(response)
      sentiment = res["sentiment"]
      confidence = res["confidence"]
      reasoning = res["reasoning"]
      { sentiment: sentiment || "unknown", confidence: confidence || 0.0, raw: response, reasoning: reasoning || "ไม่มีข้อมูล" }
    end
  end
end
