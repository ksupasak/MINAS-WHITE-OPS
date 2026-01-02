class PostSubject
  include Mongoid::Document
  include Mongoid::Timestamps

  SENTIMENTS = %w[positive negative neutral mixed].freeze

  field :post_id, type: BSON::ObjectId
  field :subject_id, type: BSON::ObjectId
  field :sentiment, type: String
  field :analayzed_model, type: String
  field :note, type: String
  field :confidence, type: Float
  field :analyzed_at, type: Time
  field :total_duration, type: Float
  field :reasoning, type: String
  field :raw, type: String

  belongs_to :post, optional: true
  belongs_to :subject, optional: true

  index({ post_id: 1 })
  index({ subject_id: 1 })
  index({ sentiment: 1 })
  index({ model_name: 1 })

  validates :sentiment, inclusion: { in: SENTIMENTS }, allow_blank: true

  scope :positive, -> { where(sentiment: "positive") }
  scope :negative, -> { where(sentiment: "negative") }
  scope :neutral, -> { where(sentiment: "neutral") }

  def sentiment_color
    case sentiment
    when "positive" then "success"
    when "negative" then "danger"
    when "neutral" then "secondary"
    when "mixed" then "warning"
    else "secondary"
    end
  end

  def sentiment_icon
    case sentiment
    when "positive" then "▲"
    when "negative" then "▼"
    when "neutral" then "◆"
    when "mixed" then "◇"
    else "○"
    end
  end
end
