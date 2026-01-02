source "https://rubygems.org"

ruby "3.2.2"

gem "rails", "~> 7.2.2", ">= 7.2.2.1"
gem "mongoid", "~> 8.0"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "sprockets-rails"
gem "devise"
gem "pundit"
gem "bcrypt", "~> 3.1"
gem "sidekiq"
gem "sidekiq-cron"
gem "redis", ">= 4.8"
gem "neo4j-ruby-driver", "4.4.6"
gem "connection_pool", "~> 2.4"
gem "serpapi"
gem "dotenv-rails", groups: %i[development test]
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "mongoid-rspec"
end

group :development do
  gem "web-console"
end
