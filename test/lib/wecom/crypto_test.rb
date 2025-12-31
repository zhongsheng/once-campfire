require "test_helper"
require "base64"

class Wecom::CryptoTest < ActiveSupport::TestCase
  setup do
    @token = "token"
    @corp_id = "wx1234567890"
    @aes_key = Base64.strict_encode64("a" * 32).delete("=")
    @crypto = Wecom::Crypto.new(token: @token, aes_key: @aes_key, corp_id: @corp_id)
  end

  test "verify_url decrypts the echo string" do
    encrypted = encrypt_message("hello", @aes_key, @corp_id)
    timestamp = "1700000000"
    nonce = "nonce"
    signature = signature_for(@token, timestamp, nonce, encrypted)

    assert_equal "hello", @crypto.verify_url(signature, timestamp, nonce, encrypted)
  end

  test "verify_url rejects invalid signature" do
    encrypted = encrypt_message("hello", @aes_key, @corp_id)

    assert_raises Wecom::Crypto::VerificationError do
      @crypto.verify_url("bad", "1", "nonce", encrypted)
    end
  end

  private

  def encrypt_message(message, aes_key, corp_id)
    key = Base64.decode64(aes_key + "=")
    iv = key[0, 16]
    raw = SecureRandom.random_bytes(16) + [message.bytesize].pack("N") + message + corp_id
    padded = pkcs7_pad(raw, 32)

    cipher = OpenSSL::Cipher.new("AES-256-CBC")
    cipher.encrypt
    cipher.key = key
    cipher.iv = iv

    Base64.strict_encode64(cipher.update(padded) + cipher.final)
  end

  def pkcs7_pad(data, block_size)
    pad = block_size - (data.bytesize % block_size)
    pad = block_size if pad == 0
    data + pad.chr * pad
  end

  def signature_for(token, timestamp, nonce, encrypted)
    OpenSSL::Digest::SHA1.hexdigest([token, timestamp, nonce, encrypted].sort.join)
  end
end
