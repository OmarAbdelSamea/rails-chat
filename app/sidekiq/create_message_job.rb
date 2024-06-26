class CreateMessageJob
  include Sidekiq::Job

  def perform(*args)
    application_token = args[0]
    chat_number = args[1]
    message_number = args[2]
    message_content = args[3]

    chat = Chat.find([application_token, chat_number])
    sleep 5 # for testing purposes
    chat.messages.create!(number: message_number, content: message_content)
  end
end
