require "base64"

module Encryptable
  extend ActiveSupport::Concern

  class_methods do
    def encrypt_attributes(*attrs)
      attrs.each do |attr|
        field "encrypted_#{attr}", type: String

        define_method(attr) do
          encrypted_value = send("encrypted_#{attr}")
          return if encrypted_value.blank?
          decryptor.decrypt_and_verify(Base64.strict_decode64(encrypted_value))
        end

        define_method("#{attr}=") do |value|
          if value.present?
            encrypted_value = Base64.strict_encode64(decryptor.encrypt_and_sign(value))
            send("encrypted_#{attr}=", encrypted_value)
          else
            send("encrypted_#{attr}=", nil)
          end
        end
      end
    end
  end

  private

  def decryptor
    secret = Rails.application.credentials.encryption_key || ENV["ENCRYPTION_KEY"] || Rails.application.secret_key_base
    key = ActiveSupport::KeyGenerator.new(secret).generate_key("feeder-config", ActiveSupport::MessageEncryptor.key_len)
    ActiveSupport::MessageEncryptor.new(key)
  end
end
