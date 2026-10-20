class HomeController < ApplicationController
  def index
    redirect_to current_user.provider? ? provider_home_path : client_home_path
  end
end
