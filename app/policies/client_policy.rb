class ClientPolicy < ApplicationPolicy
  def show?
    user&.client?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.client? ? scope.where(user_id: user.id) : scope.none
    end
  end
end
