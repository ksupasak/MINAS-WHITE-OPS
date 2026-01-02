class Project
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :description, type: String
  field :status, type: String, default: "active"
  field :customer_id, type: BSON::ObjectId
  field :sentiment_prompt, type: String

  belongs_to :customer
  has_many :subjects, dependent: :destroy
  has_many :results, dependent: :destroy
  has_many :posts, dependent: :destroy

  validates :name, :customer, presence: true

  index({ customer_id: 1 })
  index({ status: 1 })
end
