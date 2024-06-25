class MessagesController < ApplicationController
    before_action :get_chat
    before_action :get_chat_message, only: [:show, :update, :destroy]
    before_action :get_message_params, only: [:create, :update, :search]

    # GET /applications/:application_token/chats/:chat_number/messages
    def index
        json_response_messages(@chat.messages.order(number: :asc))
    end

    # TODO: Handle race condition on the messages count
    # POST /applications/:application_token/chats/:chat_number/messages 
    def create
        # create a model with the new scoped number for response
        @message = @chat.messages.new(number: @chat.messages_count + 1, content:params[:content])
        @chat.update_attributes(:messages_count => @chat.messages_count + 1)
        json_response_messages(@message, :created)
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

    # TODO: Handle race condition on the messages count
    # DELETE /applications/:application_token/chats/:chat_number/messages/:number
    def destroy
        @message.destroy!
        @chat.update_attributes(:messages_count => @chat.messages_count - 1)
        render :json => { :result => "Message Deleted Succesfully" }, :status => :created 
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

    # get the parent chat for the current messages
    def get_chat
        @chat = Chat.find([params[:application_token], params[:chat_number]])
    end

    # get the message specfied in the query params
    def get_chat_message
        @message = Message.find([params[:application_token], params[:chat_number], params[:number]])
    end  
end
