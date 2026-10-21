class ProviderPolicy < ApplicationPolicy
  def show?
    user.present? && user.provider? && record&.user_id == user.id
  end

  def edit?
    show?
  end

  def update?
    show?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.provider? ? scope.where(user_id: user.id) : scope.none
    end
  end
end
