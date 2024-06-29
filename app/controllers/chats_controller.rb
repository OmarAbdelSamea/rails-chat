class ChatsController < ApplicationController
    before_action :get_chat, only: [:show, :destroy]

    # GET /applications/:application_token/chats 
    def index
        @application = Application.find(params[:application_token])
        json_response_chats(@application.chats.order(number: :asc))
    end

    # POST /applications/:application_token/chats 
    def create
        # get the new scoped number from redis key lock result
        @count, @lock_result = update_chat_count_and_number
        # if the lock is successfully acquired
        if @lock_result != false
            # create a model with the new scoped number for response 
            @chat = Chat.new(application_token: params[:application_token], number: @count)
            # invoke sidekiq worker to create a new chat record in the db
            CreateChatJob.perform_async(params[:application_token], @count)
            json_response_chats(@chat, :created)
        else
            # if lock result is false then resource not available return error
            render :json => { :error => "Chat not created, Please try again later" }, :status => 400        
        end
    end

    # GET /applications/:application_token/chats/:number
    def show
        json_response_chats(@chat)
    end

    # DELETE /applications/:application_token/chats/:number
    def destroy
        # lock the chat number in redis and decrement the chats count
        @lock_result = update_chat_count_and_number(destroy: true)
        # if the lock is successful
        if @lock_result != false
            # if lock is successful and count value decremented then delete the chat
            @chat.destroy!
            render :json => { :result => "Chat Deleted Succesfully" }, :status => :created 
        else
            # if the lock is not successful then return error message to try again later
            render :json => { :error => "Chat not deleted, Please try again later" }, :status => 400        
        end
    end

    private

    # Gets the chat specfied in the query params
    def get_chat
        @chat = Chat.find([params[:application_token], params[:number]])
    end

    # gets the next scoped chat number from redis
    def update_chat_count_and_number(destroy: false)
        # lock the chat number in redis before incrementing the chats count and increment the chat number
        @lock_result = $red_lock.lock("application_token:#{params[:application_token]}", 2000)
        # if the lock is successful
        if @lock_result != false
            @redis_value = $redis.get("application_token:#{params[:application_token]}/chats_count#chat_number")
            @chat_count_number_arr = ($redis.get("application_token:#{params[:application_token]}/chats_count#chat_number") || "0#0").split('#')
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
            $redis.set("application_token:#{params[:application_token]}/chats_count#chat_number", "#{@chats_count}##{@chat_number}")
            # unlock the chat number
            @unlock = $red_lock.unlock(@lock_result)
            return @chat_number, @lock_result
        else
            return 0, false
        end
    end
end
