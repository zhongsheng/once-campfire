require "base64"
require "openssl"
require "securerandom"

module Wecom
  class Crypto
    class VerificationError < StandardError; end

    def initialize(token:, aes_key:, corp_id:)
      @token = token
      @aes_key = aes_key
      @corp_id = corp_id
    end

    def verify_url(signature, timestamp, nonce, echo_str)
      raise VerificationError unless verify_signature(signature, timestamp, nonce, echo_str)

      decrypt(echo_str)
    end

    def verify_signature(signature, timestamp, nonce, encrypted)
      signature == signature_for(timestamp, nonce, encrypted)
    end

    def decrypt(encrypted)
      cipher = OpenSSL::Cipher.new("AES-256-CBC")
      cipher.decrypt
      cipher.key = decoded_aes_key
      cipher.iv = decoded_aes_key[0, 16]
      raw = cipher.update(Base64.decode64(encrypted)) + cipher.final

      content = pkcs7_unpad(raw)
      msg_len = content[16, 4].unpack1("N")
      message = content[20, msg_len]
      corp_id = content[20 + msg_len..]

      raise VerificationError unless corp_id == @corp_id

      message
    rescue OpenSSL::Cipher::CipherError
      raise VerificationError
    end

    private

    def signature_for(timestamp, nonce, encrypted)
      OpenSSL::Digest::SHA1.hexdigest([@token, timestamp, nonce, encrypted].sort.join)
    end

    def decoded_aes_key
      @decoded_aes_key ||= Base64.decode64(@aes_key + "=")
    end

    def pkcs7_unpad(data)
      pad = data.bytes.last
      pad = 0 if pad < 1 || pad > 32
      data[0...-pad]
    end
  end
end
