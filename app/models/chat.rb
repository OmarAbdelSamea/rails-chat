class Chat < ApplicationRecord
    self.primary_key = :application_token, :number
    belongs_to :application, foreign_key: 'application_token', primary_key: 'token'
    has_many :messages, foreign_key: [:application_token, :chat_number], dependent: :destroy
end
