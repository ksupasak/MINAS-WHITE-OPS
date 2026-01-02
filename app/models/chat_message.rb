class ChatMessage
  include Mongoid::Document
  include Mongoid::Timestamps

  field :customer_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :session_id, type: String
  field :role, type: String  # user, assistant, system
  field :content, type: String

  belongs_to :customer, optional: true
  belongs_to :user, optional: true

  validates :role, inclusion: { in: %w[user assistant system] }
  validates :content, presence: true

  index({ customer_id: 1, session_id: 1, created_at: 1 })
  index({ user_id: 1, session_id: 1 })
  index({ session_id: 1, created_at: 1 })

  scope :for_session, ->(session_id) { where(session_id: session_id).order(created_at: :asc) }
  scope :recent, ->(limit = 50) { order(created_at: :desc).limit(limit) }

  def self.clear_session(session_id)
    where(session_id: session_id).destroy_all
  end
end

