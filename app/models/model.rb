class Model
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :provider, type: String # ollama, openai, anthropic, etc.
  field :model_id, type: String # The actual model identifier
  field :config, type: Hash, default: {}
  field :version, type: String
  field :host, type: String
  field :token, type: String
  field :active, type: Boolean, default: true
  field :description, type: String
  field :capabilities, type: Array, default: [] # chat, embedding, sentiment, etc.

  PROVIDERS = %w[ollama openai anthropic huggingface custom].freeze
  CAPABILITIES = %w[chat embedding sentiment summarization translation].freeze

  validates :name, presence: true
  validates :provider, inclusion: { in: PROVIDERS }, allow_blank: true

  index({ name: 1 })
  index({ provider: 1 })
  index({ active: 1 })

  scope :active, -> { where(active: true) }
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :with_capability, ->(cap) { where(:capabilities.in => [cap]) }

  def provider_icon
    case provider
    when "ollama" then "🦙"
    when "openai" then "🤖"
    when "anthropic" then "🧠"
    when "huggingface" then "🤗"
    else "◈"
    end
  end

  def display_name
    "#{provider_icon} #{name}"
  end
end
