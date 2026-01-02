require "securerandom"

module Graph
  class TgUpsertBatch
    def initialize(customer:, feeder:, subject_ids:, items: [])
      @customer = customer
      @feeder = feeder
      @subject_ids = Array(subject_ids).map(&:to_s)
      @items = items
      @client = Graph::TigerGraphClient.new
    end

    def call
      return if @items.empty?

      # Build batch payload for TigerGraph
      payload = build_payload

      # Upsert all vertices and edges in one batch request
      result = @client.upsert(payload)
      Rails.logger.info("TigerGraph upsert result: #{result}")

      SecureRandom.uuid
    rescue StandardError => e
      Rails.logger.error("TigerGraph upsert failed: #{e.message}")
      Rails.logger.error(e.backtrace.first(10).join("\n"))
      raise e
    end

    private

    def build_payload
      vertices = {}
      edges = {}

      @items.each do |item|
        params = base_params(item)

        # Source vertex
        vertices["Source"] ||= {}
        vertices["Source"][params[:source_id]] = {
          id: { value: params[:source] },
          source_id: { value: params[:source_id] },
          name: { value: params[:source] },
          display_name: { value: params[:source] },
          channel: { value: params[:channel] },
          channel_id: { value: params[:channel_id] }
        }

        # Post vertex
        vertices["Post"] ||= {}
        vertices["Post"][params[:post_id]] = {
          id: { value: params[:post_id] },
          post_id: { value: params[:post_id] },
          name: { value: params[:title] },
          title: { value: params[:title] },
          text: { value: params[:text] },
          channel: { value: params[:channel] },
          channel_id: { value: params[:channel_id] },
          created_at: { value: params[:created_at] },
          ref_type: { value: params[:ref_type] },
          subject_ids: { value: params[:subject_ids] }
        }

        # Channel vertex
        vertices["Channel"] ||= {}
        vertices["Channel"][params[:channel]] = {
          name: { value: params[:channel] }
        }

        # Source -> POSTED -> Post edge
        edges["Source"] ||= {}
        edges["Source"][params[:source_id]] ||= {}
        edges["Source"][params[:source_id]]["POSTED"] ||= {}
        edges["Source"][params[:source_id]]["POSTED"]["Post"] ||= {}
        edges["Source"][params[:source_id]]["POSTED"]["Post"][params[:post_id]] = {}

        # Post -> IN_CHANNEL -> Channel edge
        edges["Post"] ||= {}
        edges["Post"][params[:post_id]] ||= {}
        edges["Post"][params[:post_id]]["IN_CHANNEL"] ||= {}
        edges["Post"][params[:post_id]]["IN_CHANNEL"]["Channel"] ||= {}
        edges["Post"][params[:post_id]]["IN_CHANNEL"]["Channel"][params[:channel]] = {}

        # Reference edges
        if item[:ref_post_id].present?
          # Create ref post if not exists
          vertices["Post"][params[:ref_post_id]] ||= {
            id: { value: params[:ref_post_id] },
            post_id: { value: params[:ref_post_id] }
          }

          # Post -> REFERS_TO -> Post edge
          edges["Post"][params[:post_id]]["REFERS_TO"] ||= {}
          edges["Post"][params[:post_id]]["REFERS_TO"]["Post"] ||= {}
          edges["Post"][params[:post_id]]["REFERS_TO"]["Post"][params[:ref_post_id]] = {
            ref_type: { value: params[:ref_type] }
          }
        end

        # Hashtag vertices and edges
        Array(item[:hashtags]).each do |tag|
          vertices["HashTag"] ||= {}
          vertices["HashTag"][tag] = {
            tag: { value: tag }
          }

          # Post -> HAS_TAG -> HashTag edge
          edges["Post"][params[:post_id]]["HAS_TAG"] ||= {}
          edges["Post"][params[:post_id]]["HAS_TAG"]["HashTag"] ||= {}
          edges["Post"][params[:post_id]]["HAS_TAG"]["HashTag"][tag] = {}
        end
      end

      { vertices: vertices, edges: edges }
    end

    def base_params(item)
      {
        post_id: item[:post_id].to_s,
        title: item.dig(:raw, :title) || item[:title] || "",
        source: item[:source] || "",
        source_id: item[:source_id].to_s,
        channel: item[:channel] || "",
        channel_id: item[:channel_id].to_s,
        text: item[:text] || "",
        created_at: (item[:created_at] || Time.current).iso8601,
        ref_type: item[:ref_type] || "",
        ref_post_id: item[:ref_post_id]&.to_s,
        subject_ids: @subject_ids,
        hashtags: item[:hashtags] || []
      }
    end
  end
end

