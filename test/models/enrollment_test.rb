require "test_helper"
require_relative "../support/domain_accounts"

class EnrollmentTest < ActiveSupport::TestCase
  include DomainAccounts

  setup do
    @client = create_test_account("client", "Enrollment Client").client
    @provider = create_test_account("provider", "Enrollment Provider").provider
  end

  test "both relationship queries include shared clients different plans and empty profiles" do
    other = create_test_account("client", "Other Enrollment Client").client
    second = create_test_account("provider", "Second Enrollment Provider").provider
    empty_provider = create_test_account("provider", "Available Provider").provider
    @client.enrollments.create!(provider: @provider, plan: :basic)
    @client.enrollments.create!(provider: second, plan: :premium)
    other.enrollments.create!(provider: @provider, plan: :premium)
    assert_equal [ @client.id, other.id ], @provider.clients.order(:id).pluck(:id)
    assert_equal [ @provider.id, second.id ], @client.providers.order(:id).pluck(:id)
    assert_equal %w[basic premium], @client.enrollments.order(:plan).pluck(:plan)
    assert_empty empty_provider.clients
    assert_empty create_test_account("client", "Empty Enrollment Client").client.providers
  end

  test "plans ownership references and duplicates are validated and enforced by the database" do
    empty_provider = create_test_account("provider", "Available Provider").provider
    @client.enrollments.create!(provider: @provider, plan: :basic)
    enrollment = Enrollment.new(client: @client, provider: empty_provider)
    assert_equal "basic", enrollment.plan
    assert enrollment.valid?
    [ nil, "", "gold" ].each do |plan|
      enrollment.plan = plan
      assert_not enrollment.valid?
    end
    assert_not Enrollment.new(client: @client, provider: @provider).valid?
    assert_not Enrollment.new(client: @client).valid?
    assert_not Enrollment.new(provider: @provider).valid?
    attributes = { client_id: @client.id, provider_id: empty_provider.id }
    [ [ { plan: "gold" }, ActiveRecord::StatementInvalid ], [ { plan: nil }, ActiveRecord::NotNullViolation ],
      [ { client_id: -1 }, ActiveRecord::InvalidForeignKey ], [ { provider_id: -1 }, ActiveRecord::InvalidForeignKey ],
      [ { client_id: nil }, ActiveRecord::NotNullViolation ], [ { provider_id: nil }, ActiveRecord::NotNullViolation ] ].each do |changes, error|
      assert_raises(error) do
        Enrollment.transaction(requires_new: true) { Enrollment.insert_all!([ attributes.merge(changes) ]) }
      end
    end
    # Bypass validations, as competing requests can both pass the uniqueness check.
    assert_raises(ActiveRecord::RecordNotUnique) do
      Enrollment.transaction(requires_new: true) do
        Enrollment.insert_all!([ { client_id: @client.id, provider_id: @provider.id } ])
      end
    end
    Enrollment.insert_all!([ attributes ])
    assert_equal "basic", Enrollment.find_by!(attributes).plan
    indexes = ActiveRecord::Base.connection.indexes(:enrollments)
    assert_equal [ [ [ "client_id" ], false ], [ [ "provider_id", "client_id" ], true ] ], indexes.map { |i| [ i.columns, i.unique ] }.sort
  end

  test "removing a relationship preserves client journal and other relationships" do
    second = create_test_account("provider", "Second Enrollment Provider").provider
    enrollment = @client.enrollments.create!(provider: @provider, plan: :basic)
    @client.enrollments.create!(provider: second, plan: :premium)
    entry = @client.journal_entries.create!(provider: @provider, text: "Journal survives relationship removal")
    journals = [ [ entry.id, entry.text ] ]
    enrollment.destroy!
    assert Client.exists?(@client.id)
    assert Provider.exists?(@provider.id)
    assert_equal journals, @client.journal_entries.order(:id).pluck(:id, :text)
    assert_equal 1, @client.enrollments.count
    assert_not_includes @provider.clients, @client
  end
end
