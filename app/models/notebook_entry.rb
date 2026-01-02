class NotebookEntry
  include Mongoid::Document
  include Mongoid::Timestamps

  field :customer_id, type: BSON::ObjectId
  field :subject_id, type: BSON::ObjectId
  field :post_id, type: BSON::ObjectId
  field :text, type: String
  field :embedding, type: Array, default: []

  index({ customer_id: 1, created_at: -1 })
  index({ subject_id: 1 })
  index({ post_id: 1 })

  validates :customer_id, presence: true
  validates :text, presence: true

  scope :for_customer, ->(customer) { where(customer_id: customer.id) }
end
