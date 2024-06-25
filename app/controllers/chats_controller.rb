class ChatsController < ApplicationController
    before_action :get_application
    before_action :get_application_chat, only: [:show, :update, :destroy]

    # GET /applications/:application_token/chats 
    def index
        json_response_chats(@application.chats.order(number: :asc))
    end

    # TODO: Handle race condition on the chats count
    # POST /applications/:application_token/chats 
    def create
        # create a model with the new scoped number for response 
        @chat = @application.chats.new(number: @application.chats_count + 1)
        @application.update_attributes(:chats_count => @application.chats_count + 1)
        json_response_chats(@chat, :created)
    end

    # GET /applications/:application_token/chats/:number
    def show
        json_response_chats(@chat)
    end

    # TODO: Handle race condition on the chats count
    # DELETE /applications/:application_token/chats/:number
    def destroy
        @chat.destroy
        @application.update_attributes(:chats_count => @application.chats_count - 1)
        render :json => { :result => "Chat Deleted Succesfully" }, :status => :created 
    end

    private

    # Gets the application specified in the query params
    def get_application
        @application = Application.find(params[:application_token])
    end

    # Gets the chat specfied in the query params
    def get_application_chat
        @chat = Chat.find([params[:application_token], params[:number]])
    end
end
