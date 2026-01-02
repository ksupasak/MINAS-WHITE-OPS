class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!, unless: :devise_controller?
  before_action :set_current_context

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_current_context
    Current.user = current_user
    Current.customer = current_user&.customer
  end

  def user_not_authorized
    respond_to do |format|
      format.html { redirect_to request.referer || root_path, alert: "You are not authorized to perform this action." }
      format.json { render json: { error: "forbidden" }, status: :forbidden }
    end
  end
end
