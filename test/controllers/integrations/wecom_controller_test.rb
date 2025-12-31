require "test_helper"
require "base64"

class Integrations::WecomControllerTest < ActionDispatch::IntegrationTest
  setup do
    @token = "token"
    @corp_id = "wx1234567890"
    @aes_key = Base64.strict_encode64("a" * 32).delete("=")

    ENV["WECOM_TOKEN"] = @token
    ENV["WECOM_AES_KEY"] = @aes_key
    ENV["WECOM_CORP_ID"] = @corp_id
  end

  teardown do
    ENV.delete("WECOM_TOKEN")
    ENV.delete("WECOM_AES_KEY")
    ENV.delete("WECOM_CORP_ID")
  end

  test "verify returns decrypted echostr" do
    encrypted = encrypt_message("hello", @aes_key, @corp_id)
    timestamp = "1700000000"
    nonce = "nonce"
    signature = signature_for(@token, timestamp, nonce, encrypted)

    get integrations_wecom_url, params: { msg_signature: signature, timestamp: timestamp, nonce: nonce, echostr: encrypted }

    assert_response :success
    assert_equal "hello", response.body
  end

  test "receive enqueues message job" do
    message_xml = <<~XML
      <xml>
        <ToUserName><![CDATA[toUser]]></ToUserName>
        <FromUserName><![CDATA[fromUser]]></FromUserName>
        <CreateTime>1700000000</CreateTime>
        <MsgType><![CDATA[text]]></MsgType>
        <Content><![CDATA[hi]]></Content>
        <MsgId>12345</MsgId>
        <ChatId><![CDATA[chat123]]></ChatId>
      </xml>
    XML

    encrypted = encrypt_message(message_xml, @aes_key, @corp_id)
    timestamp = "1700000001"
    nonce = "nonce"
    signature = signature_for(@token, timestamp, nonce, encrypted)
    payload = <<~XML
      <xml>
        <Encrypt><![CDATA[#{encrypted}]]></Encrypt>
      </xml>
    XML

    assert_enqueued_with(job: WecomMessageJob) do
      post integrations_wecom_url(msg_signature: signature, timestamp: timestamp, nonce: nonce),
        params: payload,
        headers: { "CONTENT_TYPE" => "text/xml" }
    end

    assert_response :success
  end

  test "receive rejects invalid signature" do
    encrypted = encrypt_message("<xml></xml>", @aes_key, @corp_id)
    payload = <<~XML
      <xml>
        <Encrypt><![CDATA[#{encrypted}]]></Encrypt>
      </xml>
    XML

    post integrations_wecom_url(msg_signature: "bad", timestamp: "1", nonce: "nonce"),
      params: payload,
      headers: { "CONTENT_TYPE" => "text/xml" }

    assert_response :unauthorized
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
