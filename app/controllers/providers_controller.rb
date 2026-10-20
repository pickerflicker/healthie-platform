class ProvidersController < ApplicationController
  def show
    authorize Provider
    @provider = policy_scope(Provider).find(current_user.provider.id)
  end
end
