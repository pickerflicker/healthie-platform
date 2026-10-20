class ClientsController < ApplicationController
  def show
    raise Pundit::NotAuthorizedError unless current_user.client?

    @client = policy_scope(Client).find(current_user.client.id)
    authorize @client
  end
end
