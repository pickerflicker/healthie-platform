class ProviderPolicy < ApplicationPolicy
  def show?
    user&.provider? && record.user_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.provider? ? scope.where(user_id: user.id) : scope.none
    end
  end
end
