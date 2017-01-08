class LineMessagesController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :authenticate_line_user!

  def incoming
    events.each do |event|
      case event
      when Line::Bot::Event::Message then msg_event_handler(event)
      end
    end

    head :ok
  end


  private

  def authenticate_line_user!
    http_body = request.raw_post
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    head :unauthorized unless client.validate_signature(http_body, signature)
  end

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV['LINE_CH_SECRET']
      config.channel_token = ENV['LINE_CH_ACCESS_TOKEN']
    }
  end

  def events
    @events ||= client.parse_events_from(request.raw_post)
  end

  def msg_event_handler(event)
    case event.type
    when Line::Bot::Event::MessageType::Text
      message = { type: 'text', text: event.message['text'] }
      client.reply_message(event['replyToken'], message)
    end
  end
end
