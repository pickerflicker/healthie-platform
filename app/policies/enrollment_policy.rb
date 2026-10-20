class EnrollmentPolicy < ApplicationPolicy
  def index?
    user&.client? || user&.provider? || false
  end

  def create?
    user&.client? && record.client_id == user.client.id
  end

  def destroy?
    create?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.client?
        scope.where(client_id: user.client.id)
      elsif user&.provider?
        scope.where(provider_id: user.provider.id)
      else
        scope.none
      end
    end
  end
end
