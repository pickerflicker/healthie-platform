class ProvidersController < ApplicationController
  def show
    @provider = current_user.provider
    authorize @provider, policy_class: ProviderPolicy
  end
end
