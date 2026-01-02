module Feeders
  class RunFeeder
    def initialize(feeder_id, subject_id: nil, channel: nil, regional: nil, start_index: 0)
      @feeder_id = feeder_id
      @subject_id = subject_id
      @channel = channel
      @regional = regional
      @start_index = start_index.to_i
      puts "feeder_id: #{feeder_id}, subject_id: #{subject_id}, channel: #{channel}, regional: #{regional}, start: #{@start_index}"
    end

    def call
      feeder = Feeder.find(@feeder_id)
      result = nil
      feeder.update(status: "running", last_run_at: Time.current)
      subjects = fetch_subjects(feeder)
      result = feeder.results.create!(
        customer: feeder.customer,
        project: subjects.first&.project,
        channel: @channel,
        regional: @regional,
        status: "running",
        start_index: @start_index,
        started_at: Time.current,
        subject_ids: subjects.map(&:id)
      )
      puts feeder.to_json
       puts subjects.to_json

      adapter = adapter_for(feeder)
   
      items_list = []
      raw_list = []

      subjects.each do |subject|
        raw = adapter.fetch(
          feeder: feeder,
          subject: subject,
          channel: @channel,
          regional: @regional,
          start_index: @start_index
        )
        puts "raw : #{raw.size}"
        raw_list << raw
      end

      result.update(
        status: "finished",
        finished_at: Time.current,
        raw: raw_list.to_json
      )
      
      items = adapter.process_result(result)
      feeder.upsert_items(result, items) if items.present?
       

      # items = items_list
      # new_items = []
      # for i in items

      #      post = Post.where(:post_id => i[:post_id]).first

      #      channel = Channel.where(:name => i[:channel]).first
      #      if channel.blank?
      #       channel = Channel.create!(:name => i[:channel])
      #      end
      #      source = Source.where(:source_id => i[:source_id], :channel_id => channel.id).first
      #      if source.blank?
      #       source = Source.create!(:source_id => i[:source_id], :name => i[:source], :channel => i[:channel], :channel_id => channel.id)
      #      end
      #      if post.blank?
      #       i[:channel_id] = channel.id
      #       i[:source_id] = source.id
      #       i[:subject_id] = i[:subject_id]
      #       i[:ref_type] = "post"
      #       i[:result_id] = result.id
      #       post = Post.create!(i)
      #       new_items <<i
      #      end
      # end

      # puts "items: #{new_items.inspect}"
      
      # batch_id = Graph::UpsertBatch.new(customer: feeder.customer, feeder: feeder, subject_ids: subjects.map(&:id), items: items).call
      # # batch_id = Graph::TgUpsertBatch.new(customer: feeder.customer, feeder: feeder, subject_ids: subjects.map(&:id), items: items).call

      # result.update(
      #   status: "finished",
      #   finished_at: Time.current,
      #   posts_count: new_items.count,
      #   # sources_count: items.map { |i| i[:source_id] }.uniq.count,
      #   hashtags_count: new_items.sum { |i| Array(i[:hashtags]).size },
      #   neo4j_batch_id: batch_id,
      #   raw: raw_list.to_json
      # )

      feeder.update(status: "idle")
      result
    rescue StandardError => e
      puts e.message
      puts e.backtrace.join("\n")
      Rails.logger.error("Feeder #{@feeder_id} failed: #{e.message}")
      result&.update(status: "failed", error_messages: [e.message], finished_at: Time.current)
      feeder&.update(status: "failed") if defined?(feeder) && feeder
      raise e
    end

    private

    def fetch_subjects(feeder)
      scope = feeder.subjects
      scope = scope.where(id: @subject_id) if @subject_id.present?
      scope
    end

    def adapter_for(feeder)
      case feeder.feeder_type.name.downcase
      when /serp/
        Feeders::Adapters::SerpapiAdapter.new(feeder: feeder)
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
end
