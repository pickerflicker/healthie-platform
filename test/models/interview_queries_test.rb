require "test_helper"

class InterviewQueriesTest < ActiveSupport::TestCase
  setup { Rails.application.load_seed }

  test "four direct queries return intentional seed identities and explicitly ordered entries" do
    provider = User.find_by!(email: "provider@healthie.example").provider
    client = User.find_by!(email: "client@healthie.example").client
    assert_equal [ "Sam Chen", "Alex Rivera" ], provider.clients.order("enrollments.created_at DESC", "enrollments.id DESC").preload(:user).map(&:name)
    assert_equal [ "Taylor Reed", "Morgan Patel" ], client.providers.order("enrollments.created_at DESC", "enrollments.id DESC").preload(:user).map(&:name)
    expected = [ "An evening stretch helped me unwind.", "Prepared lunch for tomorrow.", "Walked after breakfast and felt energized." ]
    assert_equal expected, client.journal_entries.order(created_at: :desc, id: :desc).pluck(:text)
    assert_equal [ "Tried a new breakfast recipe.", *expected ], provider.journal_entries.order(created_at: :desc, id: :desc).pluck(:text)
    assert_empty User.find_by!(email: "empty-provider@healthie.example").provider.journal_entries
    assert_empty User.find_by!(email: "empty-client@healthie.example").client.journal_entries
  end

  test "multi-client feed breaks cross-client timestamp ties by ID without duplicates or unrelated entries" do
    provider = User.find_by!(email: "provider@healthie.example")
    client = User.find_by!(email: "client@healthie.example").client
    other = User.find_by!(email: "unrelated-client@healthie.example").client
    empty = User.find_by!(email: "empty-client@healthie.example").client
    timestamp = Time.utc(2026, 10, 21, 10)
    first = client.journal_entries.create!(text: "first cross-client tie", created_at: timestamp)
    second = other.journal_entries.create!(text: "second cross-client tie", created_at: timestamp)
    empty.journal_entries.create!(text: "unrelated newer entry", created_at: timestamp + 1.day)
    expected = [ second.id, first.id, *JournalEntry.where(client_id: [ client.id, other.id ]).where.not(id: [ first.id, second.id ]).order(created_at: :desc, id: :desc).pluck(:id) ]
    assert_equal expected, provider.provider.journal_entries.order(created_at: :desc, id: :desc).pluck(:id)
    assert_equal expected, JournalEntryPolicy::Scope.new(provider, JournalEntry.all).resolve.order(created_at: :desc, id: :desc).pluck(:id)
    assert_not JournalEntryPolicy.new(provider, empty.journal_entries.first).show?
    [ client, other ].each do |record|
      assert JournalEntryPolicy.new(provider, record.journal_entries.first).show?
    end
  end
end
