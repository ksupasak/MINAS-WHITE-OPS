class Post
  include Mongoid::Document
  include Mongoid::Timestamps

  field :post_id, type: String

  field :channel_id, type: BSON::ObjectId # facebook
  field :channel, type: String


  field :title, type: String  #text
  field :link, type: String  #link
  field :text, type: String

  field :ref_post, type: String  #ref_post
  field :ref_type, type: String
  field :snippet, type: String  #

  field :source, type: String
  field :source_id, type: BSON::ObjectId

  field :date_text, type: String
  field :thumbnail, type: String
  field :hashtags, type: Array
  field :raw, type: String

  field :ref_post_id, type: BSON::ObjectId 

  field :subject_id, type: BSON::ObjectId
  field :subject, type: String
  field :result_id, type: BSON::ObjectId
  field :feeder_id, type: BSON::ObjectId
  field :project_id, type: BSON::ObjectId
  field :customer_id, type: BSON::ObjectId
  field :regional, type: String

  field :sentiment_status, type: String
  field :index_status, type: String

belongs_to :project, optional: true
belongs_to :result, optional: true
belongs_to :subject, optional: true
belongs_to :customer, optional: true

  def analyze_sentiment

    project = Project.find(self.project_id)
    subjects = project.subjects

    PostSubject.where(post_id: self.id).destroy_all
    prompt = ""
    prompt = project.sentiment_prompt if project.sentiment_prompt.present?

    subjects.each do |subject|
      text = "#{prompt}\n #{self.title} #{self.text} #{self.snippet}"
      sentiment = Ai::SentimentService.new.analyze("จากข้อมูล: #{text} มีความคิดเห็นต่อ: #{subject.name} อย่างไร")
      puts sentiment.inspect
      PostSubject.create(post_id: self.id, subject_id: subject.id, sentiment: sentiment[:sentiment], confidence: sentiment[:confidence],reasoning: sentiment[:reasoning], analyzed_at: Time.now, raw: sentiment.to_json, total_duration: sentiment[:total_duration], analayzed_model: sentiment[:model])
    end
    
    self.update(sentiment_status: "completed")

  end


  def index_post

    text = "#{self.title} #{self.text} #{self.snippet}"
    notebook = Ai::NotebookService.new
    notebook.index_post(customer_id: self.customer_id, subject_id: self.subject_id, post_id: self.id, text: text)

    self.update(index_status: "completed")

  end
end
