# Focused scenarios own their relationships and journal data; demo seeds are separate.
module DomainAccounts
  PASSWORD = "Focused-tests-2026"

  def create_test_account(role, name)
    User.create_account!(role: role, name: name,
      email: "#{name.parameterize}@example.test", password: PASSWORD)
  end
end
