class Customer
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :slug, type: String
  field :plan, type: String
  field :status, type: String, default: "active"

  has_many :users, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :feeders, dependent: :destroy
  has_many :results, dependent: :destroy

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true

  index({ slug: 1 }, unique: true)
  index({ status: 1 })

  before_validation :set_slug

  private

  def set_slug
    self.slug ||= name&.parameterize
  end
end
