class RunSerpapiFeederJob
  include Sidekiq::Job

  sidekiq_options queue: :default

  def perform(feeder_id, subject_id = nil)
    Feeders::RunFeeder.new(feeder_id, subject_id: subject_id).call
  end
end
