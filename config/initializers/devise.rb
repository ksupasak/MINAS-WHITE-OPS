Devise.setup do |config|
  config.mailer_sender = "no-reply@social-monitor.local"
  require "devise/orm/mongoid"

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = false
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 10..128
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete
  config.secret_key = ENV["DEVISE_SECRET_KEY"] if ENV["DEVISE_SECRET_KEY"].present?
end
