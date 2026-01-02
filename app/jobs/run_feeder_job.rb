class RunFeederJob
  include Sidekiq::Job

  sidekiq_options queue: :default

  def perform(feeder_id, subject_id = nil, channel = nil, regional = nil, start_index = 0)
    Feeders::RunFeeder.new(feeder_id, subject_id: subject_id, channel: channel, regional: regional, start_index: start_index).call
  end




end
