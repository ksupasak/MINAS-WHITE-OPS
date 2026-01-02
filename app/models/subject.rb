class Subject
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :query, type: String
  field :language, type: String
  field :country, type: String
  field :active, type: Mongoid::Boolean, default: true
  field :customer_id, type: BSON::ObjectId

  belongs_to :project
  belongs_to :customer
  has_many :feeder_subjects, dependent: :destroy

  validates :name, :query, :project, :customer, presence: true

  before_validation :sync_customer

  index({ project_id: 1 })
  index({ customer_id: 1 })
  index({ active: 1 })

  scope :for_customer, ->(customer) { where(customer_id: customer.id) }

  def feeders
    Feeder.where(:id.in => feeder_subjects.pluck(:feeder_id))
  end

  private

  def sync_customer
    self.customer_id ||= project&.customer_id
  end
end
