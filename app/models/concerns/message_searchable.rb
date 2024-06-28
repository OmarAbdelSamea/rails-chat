module MessageSearchable
    extend ActiveSupport::Concern

    included do
        include Elasticsearch::Model
        include Elasticsearch::Model::Callbacks

        settings analysis: {
          filter: {
            ngram_filter: { type: "nGram", min_gram: 3, max_gram: 12 }
          },
          analyzer: {
                index_ngram_analyzer: {
                    type: 'custom',
                    tokenizer: 'standard',
                    filter: ['lowercase', 'ngram_filter']
                },
                search_ngram_analyzer: {
                    type: 'custom',
                    tokenizer: 'standard',
                    filter: ['lowercase']
                }
            }
        } do
          mapping do
              indexes :content, type: 'text', analyzer: "index_ngram_analyzer", search_analyzer: "search_ngram_analyzer"
          end
        end 

        def self.search_content(application_token:, chat_number:, content:)
            params = {          
              query: {
                bool: {
                  must: [
                    {
                      match: {
                        content: "*#{content}*"
                      }
                    },
                    {
                      match: {
                        application_token: application_token
                      }
                    },
                    {
                      match: {
                        chat_number: chat_number
                      }
                    }
                  ]
                }
              }
            }
        
            return Message.search(params)
        end
    end
end