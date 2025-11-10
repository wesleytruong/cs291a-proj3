Rails.application.routes.draw do
  # Health check
  get "health", to: "health#show"
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication routes
  post "auth/register", to: "auth#register"
  post "auth/login", to: "auth#login"
  post "auth/logout", to: "auth#logout"
  post "auth/refresh", to: "auth#refresh"
  get "auth/me", to: "auth#me"

  # Conversations
  resources :conversations, only: [ :index, :show, :create ] do
    resources :messages, only: [ :index ]
  end

  # Messages
  resources :messages, only: [ :create ] do
    member do
      put :read, to: "messages#mark_read"
    end
  end

  # Expert operations
  get "expert/queue", to: "expert#queue"
  get "expert/profile", to: "expert#profile"
  put "expert/profile", to: "expert#update_profile"
  get "expert/assignments/history", to: "expert#assignment_history"
  post "expert/conversations/:conversation_id/claim", to: "expert#claim"
  post "expert/conversations/:conversation_id/unclaim", to: "expert#unclaim"

  # Update/Polling endpoints
  get "api/conversations/updates", to: "updates#conversations"
  get "api/messages/updates", to: "updates#messages"
  get "api/expert-queue/updates", to: "updates#expert_queue"

  # Root route
  root "health#show"
end
