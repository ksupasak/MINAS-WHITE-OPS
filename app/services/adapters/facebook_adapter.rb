module Adapters
  class FacebookAdapter < BaseAdapter
    def fetch(feeder:, subject:)
      super
    end

    def channel
      "Facebook"
    end
  end
end
