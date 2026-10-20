class ClientsController < ApplicationController
  def show
    authorize Client
    @client = policy_scope(Client).find(current_user.client.id)
  end
end
