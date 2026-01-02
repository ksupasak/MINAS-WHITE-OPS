require "net/http"
require "json"

module Ai
  class ChatService
    def initialize(model: nil, host: nil)
      @model = model || ENV.fetch("OLLAMA_MODEL", "qwen3:4b")
      @host = host || ENV.fetch("OLLAMA_HOST", "http://ollama:11434")
    end

    # Simple generate (single prompt)
    def generate(prompt)
      uri = URI.parse(File.join(@host, "/api/generate"))
      payload = {
        model: @model,
        prompt: prompt,
        stream: false
      }
      res = Net::HTTP.post(uri, payload.to_json, "Content-Type" => "application/json")
      raise "Ollama error #{res.code}" unless res.is_a?(Net::HTTPSuccess)
      body = JSON.parse(res.body)
      body["response"] || ""
    rescue StandardError => e
      Rails.logger.error("ChatService generate error: #{e.message}")
      "(error contacting model)"
    end

    # Chat with message history
    def chat(messages, system_prompt: nil)
      uri = URI.parse(File.join(@host, "/api/chat"))
      
      formatted_messages = []
      
      # Add system prompt if provided
      if system_prompt.present?
        formatted_messages << { role: "system", content: system_prompt }
      end
      
      # Add conversation messages
      messages.each do |msg|
        formatted_messages << {
          role: msg[:role] || msg["role"],
          content: msg[:content] || msg["content"]
        }
      end
      
      payload = {
        model: @model,
        messages: formatted_messages,
        stream: false
      }
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 30
      http.read_timeout = 120
      
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = payload.to_json
      
      res = http.request(request)
      raise "Ollama error #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)
      
      body = JSON.parse(res.body)
      body.dig("message", "content") || ""
    rescue StandardError => e
      Rails.logger.error("ChatService chat error: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      "(error contacting model: #{e.message})"
    end

    # Streaming chat with message history - yields chunks as they arrive
    def stream_chat(messages, system_prompt: nil, &block)
      uri = URI.parse(File.join(@host, "/api/chat"))
      
      formatted_messages = []
      
      # Add system prompt if provided
      if system_prompt.present?
        formatted_messages << { role: "system", content: system_prompt }
      end
      
      # Add conversation messages
      messages.each do |msg|
        formatted_messages << {
          role: msg[:role] || msg["role"],
          content: msg[:content] || msg["content"]
        }
      end
      
      payload = {
        model: @model,
        messages: formatted_messages,
        stream: true
      }
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 30
      http.read_timeout = 300
      
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = payload.to_json
      
      full_response = ""
      
      http.request(request) do |response|
        unless response.is_a?(Net::HTTPSuccess)
          error_msg = "(error: #{response.code})"
          yield({ content: error_msg, done: true }) if block_given?
          return error_msg
        end
        
        response.read_body do |chunk|
          chunk.each_line do |line|
            next if line.strip.empty?
            
            begin
              data = JSON.parse(line)
              content = data.dig("message", "content") || ""
              done = data["done"] || false
              
              full_response += content
              
              yield({ content: content, done: done, full_response: full_response }) if block_given?
            rescue JSON::ParserError => e
              Rails.logger.warn("ChatService stream parse error: #{e.message} - line: #{line}")
            end
          end
        end
      end
      
      full_response
    rescue StandardError => e
      Rails.logger.error("ChatService stream_chat error: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      error_msg = "(error contacting model: #{e.message})"
      yield({ content: error_msg, done: true }) if block_given?
      error_msg
    end

    # List available models
    def list_models
      uri = URI.parse(File.join(@host, "/api/tags"))
      res = Net::HTTP.get_response(uri)
      return [] unless res.is_a?(Net::HTTPSuccess)
      
      body = JSON.parse(res.body)
      (body["models"] || []).map { |m| m["name"] }
    rescue StandardError => e
      Rails.logger.error("ChatService list_models error: #{e.message}")
      []
    end

    def current_model
      @model
    end
  end
end
