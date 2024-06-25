class ApplicationsController < ApplicationController
    before_action :get_application, only: [:show, :update, :destroy]
    before_action :get_application_params, only: [:create, :update]

    # GET /applications 
    def index
        @applications  = Application.all
        json_response(@applications)
    end
    
    # POST /applications
    def create
        @application = Application.create!(get_application_params)
        json_response(@application, :created)
    end
    
    # GET /applications/:token
    def show
        json_response(@application)
    end

    # PUT /applications/:token
    def update
        # lock the row in MySQL until the record is updated
        @application.with_lock do
            @application.update(get_application_params)
        end
        json_response(@application, :created)
    end

    # DELETE /applications/:token
    def destroy
        @application.destroy
        render :json => { :result => "Application Deleted Succesfully" }, :status => :created 
    end

    private

    # gets the application params from the request
    def get_application_params
        begin
            params.require(:name)
            params.permit(:name)
        rescue => exception
            render :json => { :error => exception.message }, :status => 400 
        end
    end

    # get the application specified in the query params
    def get_application
        @application = Application.find_by_token!(params[:token])
    end
end