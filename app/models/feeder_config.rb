class FeederConfig
  include Mongoid::Document
  include Mongoid::Timestamps
  include Encryptable

  # encrypt_attributes :api_key, :api_secret, :access_token, :refresh_token

  field :base_url, type: String
  field :rate_limit_policy, type: String
  field :engine, type: String, default: "google"
  field :google_domain, type: String, default: "google.com"
  field :gl, type: String
  field :hl, type: String
  field :start, type: Integer, default: 0
  field :extra, type: Hash, default: {}



  field :api_key, type: String
  field :api_secret, type: String
  field :access_token, type: String
  field :refresh_token, type: String

  belongs_to :feeder

  validates :feeder, presence: true
end
