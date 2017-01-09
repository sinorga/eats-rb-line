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
      logger.error "response error: #{resp.code}" if resp.try(:code) && resp.code != '200'
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
      text_handler(event)
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
    data = JSON.parse(event['postback']['data'])
    logger.info data
    nil
  end

  def unknown_handler(event)
    message = { type: 'text', text: '林北跨謀，說人話！' }
    client.reply_message(event['replyToken'], message)
  end

  def ignore_message(msg)
    msg =~ /^我:/
  end

  def text_handler(event)
    text = event.message['text']
    if command?(text)
      command_handler(event)
    elsif ignore_message(msg)
      nil
    else
      message = { type: 'text', text: "供三小#{text}\n吃飯了Ｒ" }
      client.reply_message(event['replyToken'], message)
    end
  end

  def command?(text)
    text =~ %r{^/}
  end

  def command_handler(event)
    _, cmd_type, cmd_data = event.message['text'].match(/^\/(.*) (.*)/).to_a
    case cmd_type
    when 'date'
      date = parse_date(cmd_data)
      reply_text_message(event, "您: #{date.to_s(:short)} 有空")
      # TODO: store to DB
    else
      unknown_handler(event)
    end

  rescue ArgumentError
    reply_text_message(event, '打什麼鬼，再給你一次機會！')
  end

  def reply_text_message(event, msg)
    message = { type: 'text', text: msg }
    client.reply_message(event['replyToken'], message)
  end

  def parse_date(day)
    # TODO: validation, day should after today + voting period
    Date.today.change(day: day.to_i)
  end
end
