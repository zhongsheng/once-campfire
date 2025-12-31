require "test_helper"

class WecomMessageJobTest < ActiveJob::TestCase
  setup do
    ENV["WECOM_CORP_ID"] = "corp"
    ENV["WECOM_CORP_SECRET"] = "secret"
    ENV["WECOM_AGENT_ID"] = "1000001"
    ENV["COZE_API_KEY"] = "coze-key"
    ENV["COZE_BOT_ID"] = "coze-bot"
  end

  teardown do
    %w[WECOM_CORP_ID WECOM_CORP_SECRET WECOM_AGENT_ID COZE_API_KEY COZE_BOT_ID].each do |key|
      ENV.delete(key)
    end
  end

  test "forwards message to coze and sends group reply" do
    stub_request(:post, "https://api.coze.com/open_api/v2/chat")
      .with(
        headers: { "Authorization" => "Bearer coze-key" },
        body: hash_including("bot_id" => "coze-bot", "query" => "hi", "user" => "fromUser")
      )
      .to_return(body: { messages: [{ role: "assistant", content: "reply" }] }.to_json)

    stub_request(:get, "https://qyapi.weixin.qq.com/cgi-bin/gettoken")
      .with(query: { corpid: "corp", corpsecret: "secret" })
      .to_return(body: { access_token: "token" }.to_json)

    stub_request(:post, "https://qyapi.weixin.qq.com/cgi-bin/externalcontact/groupchat/send")
      .with(query: { access_token: "token" }, body: hash_including("chat_id" => "chat123"))
      .to_return(body: { errcode: 0 }.to_json)

    message = {
      "MsgType" => "text",
      "FromUserName" => "fromUser",
      "Content" => "hi",
      "ChatId" => "chat123"
    }

    WecomMessageJob.perform_now(message)

    assert_requested(:post, "https://api.coze.com/open_api/v2/chat")
    assert_requested(
      :post,
      "https://qyapi.weixin.qq.com/cgi-bin/externalcontact/groupchat/send",
      query: { access_token: "token" },
      body: hash_including("chat_id" => "chat123")
    )
  end
end
