module LineBot
  class Client
    attr_reader :bot_client
    def initialize
      @bot_client = Line::Bot::Client.new { |config|
        config.channel_secret = ENV['LINE_CH_SECRET']
        config.channel_token = ENV['LINE_CH_ACCESS_TOKEN']
      }
    end

    def method_missing(method_name, *args, &block)
      bot_client.send(method_name, *args, &block)
    end

    def respond_to_missing?(method_name, include_private = false)
      bot_client.respond_to?(method_name, include_private) || super
    end
  end
end
