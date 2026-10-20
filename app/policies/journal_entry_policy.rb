class JournalEntryPolicy < ApplicationPolicy
  def index?
    user&.client? || false
  end

  def new?
    create?
  end

  def create?
    user&.client? && record.client_id == user.client.id
  end

  def show?
    create?
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
      user&.client? ? scope.where(client_id: user.client.id) : scope.none
    end
  end
end
