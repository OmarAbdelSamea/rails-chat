class Message < ApplicationRecord
    self.primary_key = :application_token, :chat_number, :number
    belongs_to :chat, foreign_key: [:application_token, :chat_number]

    validates_presence_of :content
end
