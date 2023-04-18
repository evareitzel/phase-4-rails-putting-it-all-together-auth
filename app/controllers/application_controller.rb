class ApplicationController < ActionController::API
  include ActionController::Cookies

  before_action :authorize

  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity_response


  private

  def authorize
    current_user = User.find_by(id: session[:user_id])  # @current_user
  
    render json: { errors: ["Not authorized"] }, status: :unauthorized unless current_user # unless session.include? :user_id

  end  

  def render_unprocessable_entity_response(exception) # invalid
    render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

end
