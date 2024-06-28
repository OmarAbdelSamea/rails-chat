require 'elasticsearch/model'

class Message < ApplicationRecord
    include MessageSearchable

    self.primary_key = :application_token, :chat_number, :number
    belongs_to :chat, foreign_key: [:application_token, :chat_number]

    validates_presence_of :content
end

# TODO: Add the indexing at a better execution place as recommended in the elasticsearch-rails documentation
Message.__elasticsearch__.create_index!
