class ClientPolicy < ApplicationPolicy
  def show?
    return false unless record

    if user&.client?
      record.user_id == user.id
    elsif user&.provider?
      user.provider.enrollments.exists?(client_id: record.id)
    else
      false
    end
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.client?
        scope.where(user_id: user.id)
      elsif user&.provider?
        scope.where(id: user.provider.enrollments.select(:client_id))
      else
        scope.none
      end
    end
  end
end
