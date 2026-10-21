require "test_helper"
require_relative "../support/domain_accounts"

class InterviewQueriesTest < ActiveSupport::TestCase
  include DomainAccounts

  setup do
    User.destroy_all
    @provider = create_test_account("provider", "Primary Provider").provider
    second_provider = create_test_account("provider", "Second Provider").provider
    @client = create_test_account("client", "Primary Client").client
    @other = create_test_account("client", "Other Client").client
    @empty_client = create_test_account("client", "Unrelated Client").client
    @empty_provider = create_test_account("provider", "Unrelated Provider").provider
    @client.enrollments.create!(provider: @provider, created_at: Time.utc(2026, 10, 17))
    @client.enrollments.create!(provider: second_provider, created_at: Time.utc(2026, 10, 18))
    @other.enrollments.create!(provider: @provider, created_at: Time.utc(2026, 10, 19))
    @earlier = @client.journal_entries.create!(text: "Earlier entry", created_at: Time.utc(2026, 10, 17))
    @first_tied = @client.journal_entries.create!(text: "First tied entry", created_at: Time.utc(2026, 10, 19))
    @second_tied = @client.journal_entries.create!(text: "Second tied entry", created_at: Time.utc(2026, 10, 19))
    @other_entry = @other.journal_entries.create!(text: "Other client's entry", created_at: Time.utc(2026, 10, 20))
  end

  test "four direct queries return scenario identities and explicitly ordered entries" do
    provider = @provider
    client = @client
    assert_equal [ "Other Client", "Primary Client" ], provider.clients.order("enrollments.created_at DESC", "enrollments.id DESC").preload(:user).map(&:name)
    assert_equal [ "Second Provider", "Primary Provider" ], client.providers.order("enrollments.created_at DESC", "enrollments.id DESC").preload(:user).map(&:name)
    expected = [ "Second tied entry", "First tied entry", "Earlier entry" ]
    assert_equal expected, client.journal_entries.order(created_at: :desc, id: :desc).pluck(:text)
    assert_equal [ "Other client's entry", *expected ], provider.journal_entries.order(created_at: :desc, id: :desc).pluck(:text)
    assert_empty @empty_provider.journal_entries
    assert_empty @empty_client.journal_entries
  end

  test "multi-client feed breaks cross-client timestamp ties by ID without duplicates or unrelated entries" do
    provider = @provider.user
    client = @client
    other = @other
    empty = @empty_client
    timestamp = Time.utc(2026, 10, 21, 10)
    first = client.journal_entries.create!(text: "first cross-client tie", created_at: timestamp)
    second = other.journal_entries.create!(text: "second cross-client tie", created_at: timestamp)
    empty.journal_entries.create!(text: "unrelated newer entry", created_at: timestamp + 1.day)
    expected = [ second.id, first.id, @other_entry.id, @second_tied.id, @first_tied.id, @earlier.id ]
    assert_equal expected, provider.provider.journal_entries.order(created_at: :desc, id: :desc).pluck(:id)
    assert_equal expected, JournalEntryPolicy::Scope.new(provider, JournalEntry.all).resolve.order(created_at: :desc, id: :desc).pluck(:id)
    assert_not JournalEntryPolicy.new(provider, empty.journal_entries.first).show?
    [ client, other ].each do |record|
      assert JournalEntryPolicy.new(provider, record.journal_entries.first).show?
    end
  end
end
