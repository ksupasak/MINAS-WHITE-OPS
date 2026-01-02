class User
  include Mongoid::Document
  include Mongoid::Timestamps

  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  ROLES = %w[super_admin admin member].freeze

  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time
  field :remember_created_at,    type: Time
  field :role, type: String, default: "member"

  belongs_to :customer

  validates :role, inclusion: { in: ROLES }

  index({ email: 1 }, unique: true)
  index({ customer_id: 1 })
  index({ role: 1 })
  index({ reset_password_token: 1 }, sparse: true)

  scope :for_customer, ->(customer) { where(customer_id: customer.id) }

  def super_admin?
    role == "super_admin"
  end

  def admin?
    role == "admin" || super_admin?
  end
end
