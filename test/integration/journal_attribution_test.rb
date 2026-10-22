require "test_helper"
require_relative "../support/domain_accounts"
require_relative "../support/request_authentication"

class JournalAttributionTest < ActionDispatch::IntegrationTest
  include DomainAccounts
  include RequestAuthentication

  setup do
    JournalEntry.delete_all
    User.destroy_all
    @client = create_test_account("client", "Pair Client").client
    @provider = create_test_account("provider", "First Pair Provider").provider
    @other = create_test_account("provider", "Second Pair Provider").provider
    @enrollment = @client.enrollments.create!(provider: @provider, plan: :basic)
  end

  test "create derives client and time permits explicit provider and returns ordinary validation errors" do
    log_in_as(@client.user)
    post journal_entries_path, params: { journal_entry: { text: "Only enrolled provider" } }
    assert_response :redirect
    entry = @client.journal_entries.sole
    assert_equal @provider.id, entry.provider_id
    @client.enrollments.create!(provider: @other, plan: :premium)
    [ {}, { provider_id: "" }, { provider_id: -1 } ].each do |attributes|
      assert_no_difference "JournalEntry.count" do
        post journal_entries_path, params: { journal_entry: { text: "Ambiguous or ineligible", **attributes } }
        assert_response :unprocessable_entity
        assert_select "[role=alert]", text: /Provider/
      end
    end
    travel_to Time.zone.local(2026, 10, 22, 12) do
      post journal_entries_path, params: { journal_entry: { text: "Explicit pair", provider_id: @other.id, client_id: -1, created_at: "2000-01-01" } }
      assert_response :redirect
      explicit = @client.journal_entries.find_by!(text: "Explicit pair")
      assert_equal @other.id, explicit.provider_id
      assert_equal Time.current, explicit.created_at
      patch journal_entry_path(explicit), params: { journal_entry: { text: "Edited", provider_id: @provider.id, client_id: -1, created_at: "2000-01-01" } }
      assert_response :see_other
      assert_equal [ @client.id, @other.id, Time.current ], explicit.reload.attributes.values_at("client_id", "provider_id", "created_at")
    end
    @client.enrollments.destroy_all
    assert_no_difference "JournalEntry.count" do
      post journal_entries_path, params: { journal_entry: { text: "No enrollment" } }
      assert_response :unprocessable_entity
    end
  end

  test "eleventh HTTP create is 422 but editing and deletion still work" do
    10.times { @client.journal_entries.create!(provider: @provider, text: "Existing") }
    log_in_as(@client.user)
    assert_no_difference "JournalEntry.count" do
      post journal_entries_path, params: { journal_entry: { provider_id: @provider.id, text: "Eleventh" } }
      assert_response :unprocessable_entity
      assert_select "[role=alert]", text: /Basic plan allows at most 10/
    end
    entry = @client.journal_entries.first
    patch journal_entry_path(entry), params: { journal_entry: { text: "Updated at limit" } }
    assert_response :see_other
    delete journal_entry_path(entry)
    assert_response :see_other
    assert_difference "JournalEntry.count", 1 do
      post journal_entries_path, params: { journal_entry: { provider_id: @provider.id, text: "Replacement" } }
      assert_response :redirect
    end
  end

  test "predicates scopes direct URLs and nested feeds isolate pairs including legacy and revoked history" do
    @client.enrollments.create!(provider: @other, plan: :premium)
    own = @client.journal_entries.create!(provider: @provider, text: "First pair secret")
    foreign = @client.journal_entries.create!(provider: @other, text: "Second pair secret")
    JournalEntry.insert_all!([ { client_id: @client.id, text: "Client-only legacy secret" } ])
    legacy = @client.journal_entries.find_by!(provider_id: nil)
    actor = @provider.user
    assert JournalEntryPolicy.new(actor, own).show?
    [ foreign, legacy ].each { |record| assert_not JournalEntryPolicy.new(actor, record).show? }
    %i[create? update? destroy?].each { |action| assert_not JournalEntryPolicy.new(actor, own).public_send(action) }
    assert_equal [ own.id ], JournalEntryPolicy::Scope.new(actor, JournalEntry.all).resolve.pluck(:id)
    assert_equal [ own.id ], @provider.current_journal_entries.pluck(:id)
    log_in_as(actor)
    [ journal_entries_path, client_journal_entries_path(@client) ].each do |path|
      get path
      assert_response :success
      assert_select "article", count: 1
      assert_match own.text, response.body
      assert_no_match foreign.text, response.body
      assert_no_match legacy.text, response.body
    end
    [ foreign, legacy ].each do |record|
      get journal_entry_path(record)
      assert_response :not_found
      assert_no_match record.text, response.body
    end
    @client.provider_list # Warm display cache before membership changes.
    @enrollment.destroy!
    assert_not JournalEntryPolicy.new(actor, own).show?
    assert_empty @provider.current_journal_entries
    get journal_entry_path(own)
    assert_response :not_found
    get client_journal_entries_path(@client)
    assert_response :not_found
    assert_equal 3, @client.journal_entries.count
    @client.enrollments.create!(provider: @provider)
    assert JournalEntryPolicy.new(actor, own).show?
    assert_not JournalEntryPolicy.new(actor, foreign).show?
    get journal_entry_path(own)
    assert_response :success
  end
end
