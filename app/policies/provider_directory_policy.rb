# Selecting a provider exposes directory identity, not their private workspace.
class ProviderDirectoryPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.client? ? scope.all : scope.none
    end
  end
end
