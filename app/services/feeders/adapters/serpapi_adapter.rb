require "serpapi"
require "securerandom"

module Feeders
  module Adapters
    class SerpapiAdapter
      def initialize(feeder:)
        @feeder = feeder
      end

      def fetch(feeder:, subject:, channel:, regional:, start_index: 0)
        config = feeder.feeder_config
        return [], [] unless config&.api_key.present?

        prefix = channel_prefix(channel)
        gl_config = regional.presence || config.gl

    
        # Paginate from start_index to stop_index (step by 10)
  
          puts "Fetching page: start=#{start_index}"

          params = {
            q: "#{prefix} #{subject.query}".strip,
            engine: config.engine.presence || "google",
            google_domain: config.google_domain.presence || "google.com",
            gl: gl_config,
            hl: config.hl,
            start: start_index,
            serp_api_key: config.api_key
          }.compact

          raw = perform_search(params)

       
        return raw

      rescue StandardError => e
        Rails.logger.error("SerpapiAdapter error: #{e.message}")
        Rails.logger.error(e.backtrace.first(5).join("\n"))
        return [], []
      end
     

      def process_result(result)
        if result.raw.blank?
          return
        end
      
        puts "RAW"
        puts result.raw

        list = []

        raw_list = JSON.parse(result.raw)

        raw_list.each do |raw|
          puts "PROCESSING RAW"
          puts raw.to_json

          if raw.is_a?(Array) 
            result.update(raw: raw.to_json)
            if raw.size > 0 
              raw = raw[0]
            else
              result.destroy
            end
          end

          if raw.is_a?(Hash) && raw["search_parameters"].present?
            
            puts raw.to_json
            
            query = raw["search_parameters"]["q"].split(" ")[-1]

            subject = Subject.where(query: query).first
  
            if subject.blank? == false
              puts "SUBJECT"
              puts subject.to_json
              items = normalize_results(deep_symbolize_keys(raw), subject)
              puts "ITEMS"
              items.each do |item|

                item[:subject_id] = subject.id
                item[:subject] = subject.query
                item[:result_id] = result.id
                item[:feeder_id] = result.feeder_id
                item[:project_id] = result.project_id
                item[:customer_id] = result.customer_id
                item[:regional] = result.regional

                puts item.to_json

                list << item              

              end

           
            end

          end
        
          
          
        end


        return list
  

      end

      private

      def channel_prefix(channel)
        case channel
        when "web", nil, ""
          ""
        when "facebook"
          "site:facebook.com"
        when "tiktok"
          "site:tiktok.com"
        when "instagram"
          "site:instagram.com"
        when "youtube"
          "site:youtube.com"
        when "x"
          "site:x.com OR site:twitter.com"
        else
          ""
        end
      end

      def deep_symbolize_keys(obj)
        case obj
        when Hash
          obj.each_with_object({}) do |(k, v), h|
            h[k.to_sym] = deep_symbolize_keys(v)
          end
        when Array
          obj.map { |e| deep_symbolize_keys(e) }
        else
          obj
        end
      end

      def perform_search(params)
        client = SerpApi::Client.new(
          engine: params[:engine],
          q: params[:q],
          api_key: params[:serp_api_key],
          start: params[:start],
          num: params[:num],
          google_domain: params[:google_domain],
          gl: params[:gl],
          hl: params[:hl]
        )
        result = client.search
        result
      end

      def normalize_results(raw, subject)
        organic = raw[:organic_results] || []
        return [] if organic.empty?

        organic.map do |item|
          post_id = "#{item[:source]}:#{item[:title]}"
      
          text_list = [item[:title], item[:snippet]]
          text_list << item[:snippet_highlights].join(",") if item[:snippet_highlights].present?
          text = text_list.compact.join(" - ")

          channel = detect_channel(item[:link])
          source = detect_source(item[:link], item[:source])
          source_id = item[:source]
      
          {
            post_id: post_id,
            link: item[:link],
            text: text,
            
            channel: channel,
            
            
            source: source,
            source_id: source_id,
            
            thumbnail: item[:thumbnail],
            date_text: item[:date],
            hashtags: extract_hashtags(item),
            
      
            
            created_at: Time.current,
            
            ref_type: "post",

            raw: item
          }
        end
      end

      def detect_channel(link)
        return "Generic" unless link

        if link.include?("facebook.com")
          "Facebook"
        elsif link.include?("twitter.com") || link.include?("x.com")
          "X"
        elsif link.include?("instagram.com")
          "Instagram"
        elsif link.include?("youtube.com")
          "YouTube"
        elsif link.include?("tiktok.com")
          "TikTok"
        else
          "Web"
        end
      end

      def detect_source(link,source)

        if link.include?("facebook.com")
          return source.split("·")[-1].strip
        elsif link.include?("twitter.com") || link.include?("x.com")
          return source.split("·")[-1].strip
        elsif link.include?("instagram.com")
          return source.split("·")[-1].strip
        elsif link.include?("youtube.com")
          return source.split("·")[-1].strip
        elsif link.include?("tiktok.com")
          return source.split("·")[-1].strip
        else
          return source.split("·")[-1].strip
        end
      end

      def extract_hashtags(item)
        text = [item[:title], item[:snippet]].compact.join(" ")
        text.scan(/#\w+/).map { |t| t.delete_prefix("#") }
      end
    end
  end
end
