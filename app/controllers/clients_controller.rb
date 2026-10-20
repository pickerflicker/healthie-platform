class ClientsController < ApplicationController
  def show
    @client = current_user.client
    authorize @client, policy_class: ClientPolicy
  end
end
