class WecomMessageJob < ApplicationJob
  queue_as :default

  def perform(message)
    return unless message["MsgType"] == "text"

    reply = coze_client.chat(user_id: message.fetch("FromUserName"), query: message.fetch("Content"))
    return if reply.blank?

    chat_id = message["ChatId"] || message["GroupChatId"]

    if chat_id.present?
      wecom_client.send_group_message(chat_id: chat_id, content: reply)
    else
      wecom_client.send_app_message(user_id: message.fetch("FromUserName"), content: reply)
    end
  end

  private

  def wecom_client
    settings = Current.account.settings
    Wecom::Client.new(
      corp_id: setting_or_env(settings.wecom_corp_id, "WECOM_CORP_ID"),
      corp_secret: setting_or_env(settings.wecom_corp_secret, "WECOM_CORP_SECRET"),
      agent_id: setting_or_env(settings.wecom_agent_id, "WECOM_AGENT_ID")
    )
  end

  def coze_client
    settings = Current.account.settings
    Coze::Client.new(
      api_key: setting_or_env(settings.coze_api_key, "COZE_API_KEY"),
      bot_id: setting_or_env(settings.coze_bot_id, "COZE_BOT_ID"),
      base_url: settings.coze_api_base_url.presence || ENV.fetch("COZE_API_BASE_URL", Coze::Client::DEFAULT_BASE_URL)
    )
  end

  def setting_or_env(value, env_key)
    value.presence || ENV.fetch(env_key)
  end
end
