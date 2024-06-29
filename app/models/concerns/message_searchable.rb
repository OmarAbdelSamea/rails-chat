module MessageSearchable
    extend ActiveSupport::Concern

    included do
        include Elasticsearch::Model
        include Elasticsearch::Model::Callbacks

        message_es_settings = {
          index: {
            analysis: {
              filter: {
                ngram_filter: {
                  type: "edgeNGram",
                  min_gram: 1,
                  max_gram: 20
                }
              },
              analyzer: {
                ngram_analyzer: {
                    type: 'custom',
                    tokenizer: 'standard',
                    filter: ['lowercase', 'ngram_filter']
                },
              }
            }
          }
        }

        settings message_es_settings do
          mapping do
              indexes :content, type: 'text', analyzer: "ngram_analyzer"
          end
        end 

        def self.search_content(application_token:, chat_number:, content:)
            params = {          
              query: {
                bool: {
                  must: [
                    {
                      match: {
                        content: content
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