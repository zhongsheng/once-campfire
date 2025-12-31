require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "settings" do
    accounts(:signal).settings.restrict_room_creation_to_administrators = true
    assert accounts(:signal).settings.restrict_room_creation_to_administrators?
    assert_equal(expected_settings(true), accounts(:signal)[:settings])

    accounts(:signal).update!(settings: { "restrict_room_creation_to_administrators" => "true" })
    assert accounts(:signal).reload.settings.restrict_room_creation_to_administrators?

    accounts(:signal).settings.restrict_room_creation_to_administrators = false
    assert_not accounts(:signal).settings.restrict_room_creation_to_administrators?
    assert_equal(expected_settings(false), accounts(:signal)[:settings])
    accounts(:signal).update!(settings: { "restrict_room_creation_to_administrators" => "false" })
    assert_not accounts(:signal).reload.settings.restrict_room_creation_to_administrators?
  end

  private
    def expected_settings(restrict)
      {
        "restrict_room_creation_to_administrators" => restrict,
        "wecom_token" => nil,
        "wecom_aes_key" => nil,
        "wecom_corp_id" => nil,
        "wecom_corp_secret" => nil,
        "wecom_agent_id" => nil,
        "coze_api_key" => nil,
        "coze_bot_id" => nil,
        "coze_api_base_url" => nil
      }
    end
end
