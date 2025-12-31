class Integrations::WecomController < ApplicationController
  skip_before_action :verify_authenticity_token
  allow_unauthenticated_access

  def verify
    render plain: crypto.verify_url(params[:msg_signature], params[:timestamp], params[:nonce], params[:echostr])
  rescue Wecom::Crypto::VerificationError
    head :unauthorized
  end

  def receive
    encrypted_message = Hash.from_xml(request.raw_post).dig("xml", "Encrypt")

    unless crypto.verify_signature(params[:msg_signature], params[:timestamp], params[:nonce], encrypted_message)
      return head :unauthorized
    end

    decrypted_xml = crypto.decrypt(encrypted_message)
    message = Hash.from_xml(decrypted_xml).fetch("xml")

    WecomMessageJob.perform_later(message)

    render plain: "success"
  rescue Wecom::Crypto::VerificationError
    head :unauthorized
  end

  private

  def crypto
    settings = Current.account.settings
    @crypto ||= Wecom::Crypto.new(
      token: setting_or_env(settings.wecom_token, "WECOM_TOKEN"),
      aes_key: setting_or_env(settings.wecom_aes_key, "WECOM_AES_KEY"),
      corp_id: setting_or_env(settings.wecom_corp_id, "WECOM_CORP_ID")
    )
  end

  def setting_or_env(value, env_key)
    value.presence || ENV.fetch(env_key)
  end
end
