class LineMessagesController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :authenticate_line_user!

  def incoming
    events.each do |event|
      resp = case event
             when Line::Bot::Event::Message then msg_event_handler(event)
             when Line::Bot::Event::Follow then follow_event_handler(event)
             when Line::Bot::Event::Unfollow then unfollow_event_handler(event)
             when Line::Bot::Event::Postback then postback_event_handler(event)
             end
      logger.error "response: #{resp.code}" if resp && resp.code != 200
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
    @client ||= LineBot::Client.new
  end

  def events
    @events ||= client.parse_events_from(request.raw_post)
  end

  def msg_event_handler(event)
    case event.type
    when Line::Bot::Event::MessageType::Text
      unless ignore_message(event.message['text'])
        message = { type: 'text', text: "供三小#{event.message['text']}\n吃飯了Ｒ" }
        client.reply_message(event['replyToken'], message)
      end
    else
      unknown_handler(event)
    end
  end

  def follow_event_handler(event)
    # TODO: Store user's id and info to DB
    message = { type: 'text', text: '歡迎光臨，吃好吃滿，頭好壯壯！' }
    client.reply_message(event['replyToken'], message)
  end

  def unfollow_event_handler(event)
    # TODO: remove user from DB

  end

  def postback_event_handler(event)
    logger.info event['postback']['data']
    nil
  end

  def unknown_handler(event)
    message = { type: 'text', text: '林北跨謀，說人話！' }
    client.reply_message(event['replyToken'], message)
  end

  def ignore_message(msg)
    msg =~ /^我:/
  end
end
