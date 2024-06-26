class UpdateMessageJob
  include Sidekiq::Job

  def perform(*args)
    application_token = args[0]
    chat_number = args[1]
    message_number = args[2]
    message_content = args[3]

    message = Message.find([application_token, chat_number, message_number])
    sleep 5 # for testing purposes
    message.with_lock do
      message.update!(content: message_content)
    end
  end
end
