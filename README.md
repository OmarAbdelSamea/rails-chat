<div align="center">
<h3 align="center">Rails Chat System</h3>


</div>
<!-- TABLE OF CONTENTS -->
<summary>Table of Contents</summary>
<ol>
  <li>
    <a href="#about-the-project">About the Project</a>
    <ul>
      <li><a href="#demo">Demo</a></li>
    </ul>
    <ul>
      <li><a href="#architecture">Architecture</a></li>
    </ul>
    <ul>
      <li><a href="#models">Models</a></li>
    </ul>
    <ul>
      <li><a href="#technologies">Technologies</a></li>
    </ul>
    <ul>
      <li><a href="#endpoints">Endpoints</a></li>
    </ul>
  </li>
  <li>
    <a href="#getting-started">Getting Started</a>
  </li>
  <li><a href="#development-process">Development Process</a>
  </li>
</ol>

<!-- ABOUT THE PROJECT -->
# About The Project
Chat system that allows creating new applications, chats and messages the applications supports running on multiple servers in parallel by processing requests concurrently using queues and locks.

## Demo
### Todo add demo video

## Architecture
![image](https://user-images.githubusercontent.com/57943026/176658099-9c6403ac-f963-4a3e-ad40-bca3551e2bca.png)

## Models
![rails_chat_db](https://github.com/OmarAbdelSamea/rails-chat/assets/57943026/ca1963ac-23d3-427a-bb9c-76d6eab94935)

## Technologies
- Main Framework: Ruby on Rails
- Databases: MySQL, Redis
- Containerization: Docker 
- Orchestration: Docker Compose
- Queuing: Sidekiq
- Cron Jobs: Sidekiq-cron

## Endpoints
  - ![rails_chat_openapi](https://github.com/OmarAbdelSamea/rails-chat/assets/57943026/6a547d45-d762-40db-8b80-0474bf63dbbc)

## Request and Response
### Application

#### Request 
```json
  {
    "name": "This is name of the application"
  }
```
#### Response
```json
  {
    "token": "7tftdi4PJLqXhCmQtzcypqci",
    "name": "This is name of the application",
    "chats_count": 0,
    "created_at": "2024-06-27T12:22:03.000Z",
    "updated_at": "2024-06-27T12:22:03.000Z"
  }
```

### Chat
#### Request 
`None`
#### Response
```json
  {
    "number": 1,
    "messages_count": 0,
    "application": {
      "token": "7tftdi4PJLqXhCmQtzcypqci",
      "name": "This is name of the application",
      "created_at": "2024-06-27T12:22:03.000Z"
    }
  }
```

### Message Response
#### Request 
```json
  {
    "content": "This is content of the message"
  }
```
#### Response
```json
  {
    "number": 1,
    "content": "This is content of the message",
    "chat": {
      "number": 1,
      "created_at": "2024-06-27T12:22:03.000Z"
    }
  }
```

<!-- GETTING STARTED -->
# Getting Started
```bash
1. docker-compose up
```

# Development Process
### 1. Extracting Models from requirements:
  - Application
  - Chat
  - Message
### 2. Identifying relationships between models
  - Application has many chats -> one to many relationship
  - Chat has many messages -> one to many relationship
### 3. Creating Migrations with the appropriate indices and constraints.
  - Application
    - Primary Key => Token => B-Tree indexed
  ![image](https://github.com/OmarAbdelSamea/rails-chat/assets/57943026/3340590f-5ee5-4f52-8b35-a9b97f3b757f)

  - Chat
    - Primary Key => Application_Token `Index seq 1`, Number `Index seq 2` => B-Tree indexed
  ![image](https://github.com/OmarAbdelSamea/rails-chat/assets/57943026/6a619df9-0074-43f2-aac3-ca08c9519b79)

  - Message
    - Primary Key => Application_Token `Index seq 1`, Chat_Number `Index seq 2`, Number `Index seq 3` => B-Tree indexed
  ![image](https://github.com/OmarAbdelSamea/rails-chat/assets/57943026/0015302c-c563-4f4f-ae84-5fd4dc702fcd)

  - for application token `ActiveRecord::SecureToken::ClassMethods` is used in Application model to generate a unique 24 byte unique token.


### 4. Writing unit tests (specs) for Test Driven Development approach
  - [Applications Spec](https://github.com/OmarAbdelSamea/rails-chat/blob/master/spec/requests/applications_spec.rb)

### 5. Writing RESTful endpoints in controllers
  - [Applications Controller](https://github.com/OmarAbdelSamea/rails-chat/blob/master/app/controllers/applications_controller.rb)
  - [Chats Controller](https://github.com/OmarAbdelSamea/rails-chat/blob/master/app/controllers/chats_controller.rb)
  - [Messages Controller](https://github.com/OmarAbdelSamea/rails-chat/blob/master/app/controllers/messages_controller.rb)

### 6. Adding search endpoint for messages using `elastic search`
  - Adding `ElasticSearch` in Message model
  - Note: there's a ready to use gem `Searchkick` which integrates elastic search with rails easily supporting partial matching and various tokenization methods.
  ```ruby
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
  ```
  - Creating search endpoint in Messages controller
  - Response: search string: `Github`
  ```json
  [
      {
          "_score": 3.5032253,
          "_source": {
              "content": "Bye Github",
              "application_token": "p1B2Ctt6TauRRfoATQqnvF7g",
              "chat_number": 1,
              "created_at": "2024-06-27T18:16:04.000Z",
          }
      },
      {
          "_score": 3.1505516,
          "_source": {
              "content": "Hello from Github",
              "application_token": "p1B2Ctt6TauRRfoATQqnvF7g",
              "chat_number": 1,
              "created_at": "2024-06-27T18:15:43.000Z",
          }
      }
  ]
  ```

### 7. Handling parallel processing and system distribution by using queues
  1. Analyzing options
    - Sidekiq
    - RabbitMQ
    - Kafka
  2. Selecting one of the options -> Sidekiq 
  3. Handling race conditions usind distributed locks -> Redlock

### 8. Saving centralized variables in redis
   - Saving `chats_count`, `next_chat_number`, `messages_count`, `next_message_number` in Redis instead of MySQL with each new record for higher performance. Persistent DB is updated using a cron job.

  ```ruby
    # gets the next scoped chat number from redis
    def update_chat_count_and_number(destroy: false)
        # lock the chat number in redis before incrementing the chats count and increment the chat number
        @lock_result = $red_lock.lock("application_token:#{@application.token}", 2000)
        # if the lock is successful
        if @lock_result != false
            @redis_value = $redis.get("application_token:#{@application.token}/chats_count#chat_number")
            @chat_count_number_arr = ($redis.get("application_token:#{@application.token}/chats_count#chat_number") || "0#0").split('#')
            @chats_count = @chat_count_number_arr[0].to_i
            @chat_number = @chat_count_number_arr[1].to_i
            if destroy
                # get the chats count from redis and decrement it by 1
                @chats_count -= 1
            else
                # get the chat count from redis and increment it by 1 if not found will set it to 1
                @chats_count += 1
                @chat_number += 1
            end
            # update the chat count in redis
            $redis.set("application_token:#{@application.token}/chats_count#chat_number", "#{@chats_count}##{@chat_number}")
            # unlock the chat number
            @unlock = $red_lock.unlock(@lock_result)
            return @chat_number, @lock_result
        else
            return 0, false
        end
    end
  ```

### 9. Adding Cron Job to update `chats_count` and `messages_count` in MySQL from Redis
```ruby
update_counts_persistent_storage:
  cron: "* * * * *" # this runs the job every minute for demos
  # cron: "0 * * * *" this runs the job every hour
  class: "UpdateCountsJob"
  queue: default
```

```ruby
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
```
### 10. Containerization of Rails app and orchestrations of services
  - [Dockerfile](https://github.com/OmarAbdelSamea/rails-chat/blob/master/Dockerfile)
  - [Docker-compose](https://github.com/OmarAbdelSamea/rails-chat/blob/master/docker-compose.yml)

### 11. Writing RESTful API compliant to openapi standard
[openapi.yaml](https://github.com/OmarAbdelSamea/rails-chat/blob/master/openapi.yaml)