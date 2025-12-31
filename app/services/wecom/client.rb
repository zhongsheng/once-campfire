require "net/http"
require "uri"
require "json"

module Wecom
  class Client
    BASE_URL = "https://qyapi.weixin.qq.com".freeze

    def initialize(corp_id:, corp_secret:, agent_id:)
      @corp_id = corp_id
      @corp_secret = corp_secret
      @agent_id = agent_id
    end

    def send_group_message(chat_id:, content:)
      post_json(
        "/cgi-bin/externalcontact/groupchat/send",
        access_token: access_token,
        payload: {
          chat_id: chat_id,
          msgtype: "text",
          text: { content: content }
        }
      )
    end

    def send_app_message(user_id:, content:)
      post_json(
        "/cgi-bin/message/send",
        access_token: access_token,
        payload: {
          touser: user_id,
          msgtype: "text",
          agentid: @agent_id,
          text: { content: content }
        }
      )
    end

    private

    def access_token
      @access_token ||= begin
        response = get_json("/cgi-bin/gettoken", params: { corpid: @corp_id, corpsecret: @corp_secret })
        response.fetch("access_token")
      end
    end

    def get_json(path, params: {})
      uri = URI.join(BASE_URL, path)
      uri.query = URI.encode_www_form(params)
      response = Net::HTTP.get_response(uri)
      JSON.parse(response.body)
    end

    def post_json(path, access_token:, payload:)
      uri = URI.join(BASE_URL, path)
      uri.query = URI.encode_www_form(access_token: access_token)
      request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
      request.body = JSON.generate(payload)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      JSON.parse(response.body)
    end
  end
end
