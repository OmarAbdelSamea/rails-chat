Rails.application.routes.draw do
  resources :applications, param: :token do
    resources :chats, param: :number do
      resources :messages, param: :number
        post "/messages/search", to: "messages#search"
    end
  end
end