class MessagesController < ApplicationController
    before_action :get_chat, only: [:index, :create, :destroy]
    before_action :get_chat_message, only: [:show, :update, :destroy]
    before_action :get_message_params, only: [:create, :update, :search]

    # GET /applications/:application_token/chats/:chat_number/messages
    def index
        json_response_messages(@chat.messages.order(number: :asc))
    end

    # POST /applications/:application_token/chats/:chat_number/messages 
    def create
        # get the new scoped number from redis key lock result
        @count, @lock_result = update_message_count_and_number
        # if the lock is successfully acquired
        if @lock_result != false
            # create a model with the new scoped message number for response 
            @message = @chat.messages.new(number: @count, content: params[:content])
            # invoke sidekiq worker to create a new message record in the db
            CreateMessageJob.perform_async(@chat.application_token, @chat.number ,@count, params[:content])
            json_response_messages(@message, :created)
        else
            # if lock result is false then resource not available return error
            render :json => { :error => "Message not created, Please try again later" }, :status => 400        
        end
    end
    
    # GET /applications/:application_token/chats/:chat_number/messages/:number 
    def show
        json_response_messages(@message)
    end
    
    # PUT /applications/:application_token/chats/:chat_number/messages/:number
    def update
        # lock the row in MySQL until the record is updated
        @message.with_lock do
            @message.update(get_message_params)
        end
        json_response_messages(@message, :accepted)
    end

    # DELETE /applications/:application_token/chats/:chat_number/messages/:number
    def destroy
        # lock the message number in redis before decrementing the count
        @lock_result = update_message_count_and_number(destroy: true)
        # if the lock is successful
        if @lock_result != false
            # if lock is successful and count value decremented then delete the message
            @message.destroy!
            render :json => { :result => "Message Deleted Succesfully" }, :status => :created
        else
            # if the lock is not successful then return error message to try again later
            render :json => { :error => "Message not deleted, Please try again later" }, :status => 400
        end
    end

    # TODO: Implement search functionality

    private

    # gets the application params from the request
    def get_message_params
        begin
            params.require(:content)
            params.permit(:content)
        rescue => exception
            render :json => { :error => exception.message }, :status => 400 
        end
    end

    # gets the parent chat for the current messages
    def get_chat
        @chat = Chat.find([params[:application_token], params[:chat_number]])
    end

    # gets the message specfied in the query params
    def get_chat_message
        @message = Message.find([params[:application_token], params[:chat_number], params[:number]])
    end  

    # update the messages count and the message number
    def update_message_count_and_number(destroy: false)
        # lock the message number in redis before incrementing the count
        @lock_result = $red_lock.lock("application_token:#{@chat.application_token}/chat_number:#{@chat.number}/messages_count#message_number", 2000)
        # if the lock is successful
        if @lock_result != false
            @message_count_number_arr = ($redis.get("application_token:#{@chat.application_token}/chat_number:#{@chat.number}/messages_count#message_number") || "0#0").split('#')
            @messages_count = @message_count_number_arr[0].to_i
            @message_number = @message_count_number_arr[1].to_i
            if destroy
                # get the messages count from redis and decrement it by 1
                @messages_count -= 1
            else
                # get the message count from redis and increment it by 1 if not found will set it to 1
                @messages_count += 1
                @message_number += 1
            end
            # update the message count in redis
            $redis.set("application_token:#{@chat.application_token}/chat_number:#{@chat.number}/messages_count#message_number", "#{@messages_count}##{@message_number}")
            # unlock the message number
            $red_lock.unlock(@lock_result)
            return @message_number, @lock_result
        else
            return 0, false
        end
    end
end
