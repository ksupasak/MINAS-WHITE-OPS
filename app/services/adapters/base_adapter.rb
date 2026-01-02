require "securerandom"

module Adapters
  class BaseAdapter
    def fetch(feeder:, subject:)
      [build_item(subject)]
    end

    def channel
      "generic"
    end

    private

    def build_item(subject)
      {
        post_id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        username: "demo_user",
        channel: channel,
        text: "Sample post for #{subject.name}",
        created_at: Time.current,
        hashtags: extract_hashtags(subject.query),
        ref_type: "post",
        ref_post_id: nil
      }
    end

    def extract_hashtags(query)
      query.to_s.scan(/#\w+/).map { |t| t.delete_prefix("#") }
    end
  end
end
