class ApplicationController < ActionController::API
  include ActionController::Cookies
  before_action :authenticate_request

  private

  def authenticate_request
    # This will be overridden in specific controllers for different auth methods
  end

  def current_user
    @current_user
  end

  def authenticate_with_jwt!
    token = extract_jwt_token
    return render_unauthorized("No token provided") unless token

    begin
      decoded_token = JwtService.decode(token)
      @current_user = User.find(decoded_token[:user_id])
    rescue ActiveRecord::RecordNotFound
      render_unauthorized("User not found")
    rescue JWT::DecodeError
      render_unauthorized("Invalid token")
    end
  end

  def authenticate_with_session!
    user_id = session[:user_id]
    return render_unauthorized("No session found") unless user_id

    @current_user = User.find_by(id: user_id)
    render_unauthorized("User not found") unless @current_user
  end

  def extract_jwt_token
    header = request.headers["Authorization"]
    return nil unless header && header.start_with?("Bearer ")

    header.split(" ").last
  end

  def render_unauthorized(message = "Unauthorized")
    render json: { error: message }, status: :unauthorized
  end

  def render_forbidden(message = "Forbidden")
    render json: { error: message }, status: :forbidden
  end

  def render_not_found(message = "Not found")
    render json: { error: message }, status: :not_found
  end
end
