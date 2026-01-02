module Adapters
  class XAdapter < BaseAdapter
    def fetch(feeder:, subject:)
      super
    end

    def channel
      "X"
    end
  end
end
