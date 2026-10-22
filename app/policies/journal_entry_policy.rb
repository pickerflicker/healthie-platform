class JournalEntryPolicy < ApplicationPolicy
  def index?
    user&.client? || user&.provider? || false
  end

  def new?
    create?
  end

  def create?
    (user&.client? && record.client_id == user.client.id) || false
  end

  def show?
    create? || (user&.provider? && record.provider_id == user.provider.id && user.provider.enrollments.exists?(client_id: record.client_id)) || false
  end

  def edit?
    update?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.client?
        scope.where(client_id: user.client.id)
      elsif user&.provider?
        scope.where(provider_id: user.provider.id, client_id: user.provider.enrollments.select(:client_id))
      else
        scope.none
      end
    end
  end
end
