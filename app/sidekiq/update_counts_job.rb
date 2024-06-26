class UpdateCountsJob
  include Sidekiq::Job

  def perform(*args)
    # get all applications in MySQL database
    Application.find_each do |application|
      # check if present in redis or not
      if $redis.get("application_token:#{application.token}/chats_count#chat_number").present?
        # if present then get the chat count from redis and update it in MySQL database
        chats_count_arr = $redis.get("application_token:#{application.token}/chats_count#chat_number").split('#')
        application.chats_count = chats_count_arr[0].to_i
        application.save!
      end
    end

    # get all chats in MySQL database
    Chat.find_each do |chat|
      # check if present in redis or not
      if $redis.get("application_token:#{chat.application_token}/chat_number:#{chat.number}/messages_count#message_number").present?
        # if present then get the message count from redis and update it in MySQL database
        messages_count_arr = $redis.get("application_token:#{chat.application_token}/chat_number:#{chat.number}/messages_count#message_number").split('#')
        chat.messages_count = messages_count_arr[0].to_i
        chat.save!
      end
    end
  end
end
