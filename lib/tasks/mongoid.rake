namespace :db do
  desc "Seed Mongoid data"
  task seed: :environment do
    seed_file = Rails.root.join("db", "seeds.rb")
    load(seed_file) if File.exist?(seed_file)
  end
end
