ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "spec_helper"
require "rspec/rails"
require "mongoid-rspec"

Dir[Rails.root.join("spec", "support", "**", "*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.include Mongoid::Matchers, type: :model
  config.include FactoryBot::Syntax::Methods

  config.use_transactional_fixtures = false

  config.before(:suite) do
    Mongoid.purge!
  end

  config.after(:each) do
    Mongoid.purge!
  end

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
