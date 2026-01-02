class Feeder
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :status, type: String, default: "idle"
  field :schedule_cron, type: String
  field :last_run_at, type: Time
  field :customer_id, type: BSON::ObjectId

  belongs_to :customer
  belongs_to :feeder_type
  has_one :feeder_config, dependent: :destroy
  has_many :feeder_subjects, dependent: :destroy
  has_many :results, dependent: :destroy
  accepts_nested_attributes_for :feeder_config, update_only: true

  validates :name, :customer, :feeder_type, presence: true

  index({ customer_id: 1 })
  index({ feeder_type_id: 1 })
  index({ status: 1 })

  attr_writer :subject_ids

  def subjects
    Subject.where(:id.in => feeder_subjects.pluck(:subject_id))
  end

  def subject_ids
    @subject_ids || feeder_subjects.pluck(:subject_id).map(&:to_s)
  end

  def reprocess
    
      client = Graph::Client.session(database: self.customer.slug)
      client.write_transaction do |session|
        session.run("MATCH (n) DETACH DELETE n")
      end
      client.close
  
      results = Result.where(feeder_id: id).all()
   
      results.each do |result|
      
      items  = adapter.process_result(result)
      puts "COUNT Processed: #{items.size if items}"
      upsert_items(result, items) if items.present?

     end
  
  end

  def upsert_items(result, items)
   
    new_items = []
   
    for i in items

           post = Post.where(:post_id => i[:post_id]).first

           unless post.present?

            channel = Channel.where(:name => i[:channel]).first
            if channel.blank?
              channel = Channel.create!(:name => i[:channel])
            end
            source = Source.where(:source_id => i[:source_id], :channel_id => channel.id).first
            if source.blank?
              source = Source.create!(:source_id => i[:source_id], :name => i[:source], :channel => i[:channel], :channel_id => channel.id)
            end
            if post.blank?
              i[:channel_id] = channel.id
              i[:source_id] = source.id
              i[:ref_type] = "post"
              post = Post.create!(i)
              new_items << i
            end

          end
    
    
        end
    
    batch_id = Graph::UpsertBatch.new(customer: self.customer, feeder: self, items: items).call
    result.update(neo4j_batch_id: batch_id)
    
    return new_items


  end

  def adapter
    case self.feeder_type.name.downcase
    when /serp/
      Feeders::Adapters::SerpapiAdapter.new(feeder: self)
    when /x/, /twitter/
      Adapters::XAdapter.new
    when /insta/
      Adapters::InstagramAdapter.new
    when /fb/, /face/
      Adapters::FacebookAdapter.new
    else
      Adapters::BaseAdapter.new
    end
  end


end
