class FeederType
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String

  has_many :feeders

  validates :name, presence: true, uniqueness: true

  index({ name: 1 }, unique: true)
end
