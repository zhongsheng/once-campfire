require "net/http"
require "uri"
require "json"

module Coze
  class Client
    DEFAULT_BASE_URL = "https://api.coze.com".freeze

    def initialize(api_key:, bot_id:, base_url: DEFAULT_BASE_URL)
      @api_key = api_key
      @bot_id = bot_id
      @base_url = base_url
    end

    def chat(user_id:, query:)
      response = post_json("/open_api/v2/chat", payload: {
        bot_id: @bot_id,
        user: user_id,
        query: query,
        stream: false
      })

      extract_reply(response)
    end

    private

    def post_json(path, payload:)
      uri = URI.join(@base_url, path)
      request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json", "Authorization" => "Bearer #{@api_key}")
      request.body = JSON.generate(payload)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      JSON.parse(response.body)
    end

    def extract_reply(response)
      messages = response.fetch("messages", [])
      assistant = messages.reverse.find { |message| message["role"] == "assistant" }
      assistant&.fetch("content", nil)
    end
  end
end
