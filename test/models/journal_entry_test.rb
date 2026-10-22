require "test_helper"
require_relative "../support/domain_accounts"

class JournalEntryTest < ActiveSupport::TestCase
  include DomainAccounts

  setup do
    @provider = create_test_account("provider", "Journal Provider").provider
    @client = create_test_account("client", "Journal Owner").client
    @client.enrollments.create!(provider: @provider)
  end

  test "valid owner and nonblank text are required with database reference constraints" do
    client = @client
    assert_not JournalEntry.new(text: "note").valid?
    assert_not JournalEntry.new(client: client, text: " \n").valid?
    assert_not JournalEntry.new(client_id: -1, text: "note").valid?
    [ [ nil, ActiveRecord::NotNullViolation ], [ -1, ActiveRecord::InvalidForeignKey ] ].each do |id, error|
      assert_raises(error) do
        JournalEntry.transaction(requires_new: true) { JournalEntry.insert_all!([ { client_id: id, text: "note" } ]) }
      end
    end
    assert_raises(ActiveRecord::NotNullViolation) do
      JournalEntry.transaction(requires_new: true) { JournalEntry.insert_all!([ { client_id: client.id, text: nil } ]) }
    end
    indexes = ActiveRecord::Base.connection.indexes(:journal_entries)
    assert_equal [ [ "client_id", "created_at", "id" ], [ "provider_id", "client_id", "created_at" ], [ "provider_id", "created_at", "id" ] ], indexes.map(&:columns).sort
    assert_includes JournalEntry.column_names, "provider_id"
    assert_not_includes JournalEntry.column_names, "enrollment_id"
  end

  test "explicit client query orders dates and tied IDs and edits retain position" do
    client = @client
    old = client.journal_entries.create!(provider: @provider, text: "old", created_at: 3.days.ago)
    first = client.journal_entries.create!(provider: @provider, text: "first tie", created_at: 1.day.ago.change(usec: 0))
    second = client.journal_entries.create!(provider: @provider, text: "second tie", created_at: first.created_at)
    expected = [ second.id, first.id, old.id ]
    assert_equal expected, client.journal_entries.order(created_at: :desc, id: :desc).pluck(:id)
    old.update!(text: "edited today")
    assert_equal expected, client.journal_entries.order(created_at: :desc, id: :desc).pluck(:id)
    empty = create_test_account("client", "Empty Journal").client
    assert_empty empty.journal_entries.order(created_at: :desc, id: :desc)
  end
end
