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
    # Inspect the shape before assigning: strong-parameter array filtering alone
    # would discard malformed values and could accidentally turn them into a clear.
    input = params.expect(provider: {})
    if (input.keys - [ "credentials" ]).any?
      @provider.errors.add(:base, "Only credentials can be changed here.")
    elsif !input.key?(:credentials)
      @provider.errors.add(:credentials, "must be supplied as a list of selections")
    else
      @provider.credentials = input[:credentials]
      if @provider.save
        redirect_to provider_home_path, notice: "Credentials saved.", status: :see_other
        return
      end
    end
    render :edit, formats: [ :html ], status: :unprocessable_entity
  end
end
