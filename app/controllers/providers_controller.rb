class ProvidersController < ApplicationController
  def show
    @provider = current_user.provider
    authorize @provider, policy_class: ProviderPolicy
  end

  def edit
    @provider = current_user.provider
    authorize @provider, policy_class: ProviderPolicy
  end

  def update
    @provider = current_user.provider
    authorize @provider, policy_class: ProviderPolicy
    input = params.expect(provider: {})
    if (input.keys - [ "credentials" ]).any?
      @provider.errors.add(:base, "Only credentials can be changed here.")
    elsif @provider.update(input.permit(credentials: []))
      redirect_to provider_home_path, notice: "Credentials saved.", status: :see_other
      return
    end
    render :edit, formats: [ :html ], status: :unprocessable_entity
  end
end
