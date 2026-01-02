namespace :feeders do
  desc "Run SerpAPI feeder synchronously: rake feeders:run_serpapi[feeder_id,subject_id]"
  task :run_serpapi, [:feeder_id, :subject_id] => :environment do |_, args|
    feeder_id = args[:feeder_id]
    raise "feeder_id is required" if feeder_id.blank?

    Feeders::RunFeeder.new(feeder_id, subject_id: args[:subject_id]).call
    puts "SerpAPI feeder #{feeder_id} executed"
  end
end
