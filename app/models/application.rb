class Application < ApplicationRecord
    self.primary_key = :token
    has_many :chats, foreign_key: :application_token, dependent: :destroy

    validates_presence_of :name
    has_secure_token 
end
