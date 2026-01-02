class Result
  include Mongoid::Document
  include Mongoid::Timestamps

  STATUSES = %w[pending running finished failed].freeze

  field :customer_id, type: BSON::ObjectId
  field :project_id, type: BSON::ObjectId
  field :feeder_id, type: BSON::ObjectId
 
 
  field :status, type: String, default: "pending"
  field :started_at, type: Time
  field :finished_at, type: Time
  field :posts_count, type: Integer, default: 0
  field :users_count, type: Integer, default: 0
  field :hashtags_count, type: Integer, default: 0
  field :error_messages, type: Array, default: []
  field :meta, type: Hash, default: {}
  field :neo4j_batch_id, type: String
  field :subject_ids, type: Array, default: []
  field :link, type: String
  field :thumbnail, type: String
  field :date_text, type: String
  field :start_index, type: Integer, default: 0
  field :channel, type: String
  field :regional, type: String

  field :raw, type: String

  has_many :posts, dependent: :destroy

  belongs_to :feeder
  belongs_to :customer
  belongs_to :project, optional: true

  validates :status, inclusion: { in: STATUSES }

  index({ feeder_id: 1 })
  index({ customer_id: 1 })
  index({ project_id: 1 })
  index({ subject_ids: 1 })
  index({ created_at: 1 })

  def subjects
    Subject.where(:id.in => subject_ids)
  end
  def post_count
    Post.where(result_id: self.id).count
  end

  def upsert
   
    puts "RAW LIST"
    puts self.raw.inspect
  end
end
