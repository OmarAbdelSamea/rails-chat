module Response
    def json_response(object, status = :ok)
        render json: object, status: status
    end

    def json_response_chats(object, status = :ok)
        render json: object, :only=> [:number, :messages_count], \
        :include => [:application => {:only=> [:token, :name, :created_at]}], \
        status: status 
    end

    def json_response_messages(object, status = :ok)
        render json: object, :only=> [:number, :content], \
        :include => [:chat => {:only=> [:number, :created_at]}], \
        status: status 
    end

    # def json_response_messages_search(object, status = :ok)
    #     render json: object, :except=> [:id, :chat_id, :_index, :_type, :_id], \
    #     :include => [:chat => {:only=> [:number, :created_at]}], \
    #     status: status 
    # end
end