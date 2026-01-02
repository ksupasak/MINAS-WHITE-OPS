class FeederSubject
  include Mongoid::Document
  include Mongoid::Timestamps

  field :enabled, type: Mongoid::Boolean, default: true
  field :options, type: Hash, default: {}
  field :priority, type: Integer, default: 1

  belongs_to :feeder
  belongs_to :subject

  validates :feeder, :subject, presence: true

  index({ feeder_id: 1 })
  index({ subject_id: 1 })
end
