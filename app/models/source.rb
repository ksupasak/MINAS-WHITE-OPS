class Source
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :source_id, type: String
  field :channel, type: String
  field :channel_id, type: String
end
