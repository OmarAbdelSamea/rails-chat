class CreateChatJob
  include Sidekiq::Job

  def perform(*args)
    application_token = args[0]
    chat_number = args[1]
    
    application = Application.find(application_token)
    sleep 5 # for testing purposes
    application.chats.create!(number: chat_number)
  end
end
