# Invoked only by Playwright; each test supplies its own JSON scenario on stdin.
require_relative "domain_accounts"

config = ActiveRecord::Base.connection_db_config
abort "Refusing non-local disposable test database" unless Rails.env.test? && config.database == "healthie_test" &&
  %w[127.0.0.1 localhost].include?(config.configuration_hash[:host])

scenario = JSON.parse($stdin.read)
User.destroy_all
Rails.cache.clear

User.transaction do
  accounts = scenario.fetch("accounts", {}).to_h do |label, attributes|
    [ label, User.create_account!(**attributes.symbolize_keys,
      email: "#{label}@browser.example.test", password: DomainAccounts::PASSWORD) ]
  end
  scenario.fetch("provider_credentials", {}).each do |label, credentials|
    accounts.fetch(label).provider.update!(credentials: credentials)
  end
  scenario.fetch("enrollments", []).each do |attributes|
    attributes = attributes.symbolize_keys
    Enrollment.create!(**attributes.except(:client, :provider),
      client: accounts.fetch(attributes.fetch(:client)).client,
      provider: accounts.fetch(attributes.fetch(:provider)).provider)
  end
  scenario.fetch("entries", []).each do |attributes|
    attributes = attributes.symbolize_keys
    JournalEntry.create!(**attributes.except(:client), client: accounts.fetch(attributes.fetch(:client)).client)
  end
end
