class ApplicationController < ActionController::Base
  include Pundit::Authorization
  before_action :authenticate_user!
  after_action :verify_authorized, unless: :authorization_exempt?
  allow_browser versions: :modern
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError do
    render plain: "Access denied. This page is not available for your account role.", status: :forbidden
  end

  rescue_from ActiveRecord::RecordNotFound do
    render "errors/not_found", formats: [ :html ], status: :not_found
  end

  private

  def authorization_exempt?
    devise_controller? || is_a?(HomeController)
  end

  def after_sign_in_path_for(_resource)
    root_path
  end
end
