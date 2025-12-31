class Account < ApplicationRecord
  include Joinable

  has_one_attached :logo
  has_json :settings,
    restrict_room_creation_to_administrators: false,
    wecom_token: nil,
    wecom_aes_key: nil,
    wecom_corp_id: nil,
    wecom_corp_secret: nil,
    wecom_agent_id: nil,
    coze_api_key: nil,
    coze_bot_id: nil,
    coze_api_base_url: nil
end
