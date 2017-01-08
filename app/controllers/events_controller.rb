class EventsController < ApplicationController
  protect_from_forgery with: :null_session
  # TODO: authentication

  def create
    # TODO: create event to db

    messages = [
      { type: 'text', text: '吃飯啦，選個日期吧！' }
    ]

    messages << gen_date_template

    # TODO: read all user id from db
    #'Ue2aee79ce164e30265ef965eec8472b6',
    users = ['U0a9ca05bee69c834566c61ad51ba55b5']
    users.each do |user_id|
      resp = client.push_message(user_id, messages)
      logger.error "push message: #{resp.body}" if resp.code != 200
    end

    head :ok
  end

  private

  def client
    @client ||= LineBot::Client.new
  end


  def gen_date_template
    template = default_date_template

    (0...5).each do |column_num|
      column = default_date_column

      (0...3).each do |button_num|
        column[:actions] << gen_date_action(column_num, button_num)
      end

      template[:template][:columns] << column

    end
    template
  end

  def gen_date_action(column_num, button_num)
    date = Date.today + (column_num * 3 + button_num).days
    {
      type: 'postback',
      label: date.to_s(:short),
      text: "我: #{date.to_s(:short)} 有空",
      data: "action=select_date&date=#{date.day}"
    }
  end

  def default_date_template
    {
      type: 'template',
      altText: 'To choose a date to eat together!',
      template: {
        type: 'carousel',
        columns: []
      }
    }
  end

  def default_date_column
    {
      title: '選個日期吧！',
      text: '3 dates',
      actions: []
    }
  end
end
