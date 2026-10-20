require "test_helper"

class EnrollmentTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_seed
    @client = User.find_by!(email: "client@healthie.example").client
    @provider = User.find_by!(email: "provider@healthie.example").provider
    @empty_provider = User.find_by!(email: "empty-provider@healthie.example").provider
  end

  test "both relationship queries and repeatable seeds include shared different plans and empty examples" do
    ids = Enrollment.order(:id).pluck(:id)
    Rails.application.load_seed
    assert_equal ids, Enrollment.order(:id).pluck(:id)
    assert_equal %w[client@healthie.example unrelated-client@healthie.example], @provider.clients.joins(:user).reorder("users.email").pluck("users.email")
    assert_equal %w[provider@healthie.example second-provider@healthie.example], @client.providers.joins(:user).reorder("users.email").pluck("users.email")
    assert_equal %w[basic premium], @client.enrollments.order(:plan).pluck(:plan)
    assert_empty @empty_provider.clients
    assert_empty User.find_by!(email: "empty-client@healthie.example").client.providers
  end

  test "plans ownership references and duplicates are validated and enforced by the database" do
    enrollment = Enrollment.new(client: @client, provider: @empty_provider)
    assert_equal "basic", enrollment.plan
    assert enrollment.valid?
    [ nil, "", "gold" ].each do |plan|
      enrollment.plan = plan
      assert_not enrollment.valid?
    end
    assert_not Enrollment.new(client: @client, provider: @provider).valid?
    assert_not Enrollment.new(client: @client).valid?
    assert_not Enrollment.new(provider: @provider).valid?
    attributes = { client_id: @client.id, provider_id: @empty_provider.id }
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
    journals = @client.journal_entries.order(:id).pluck(:id, :text)
    @client.enrollments.find_by!(provider: @provider).destroy!
    assert Client.exists?(@client.id)
    assert Provider.exists?(@provider.id)
    assert_equal journals, @client.journal_entries.order(:id).pluck(:id, :text)
    assert_equal 1, @client.enrollments.count
    assert_not_includes @provider.clients, @client
  end
end
