require "test_helper"

class JournalEntryTest < ActiveSupport::TestCase
  setup { Rails.application.load_seed }

  test "valid owner and nonblank text are required with database reference constraints" do
    client = User.find_by!(email: "client@healthie.example").client
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
    assert_equal [ [ "client_id", "created_at", "id" ] ], indexes.map(&:columns)
    assert_not_includes JournalEntry.column_names, "provider_id"
    assert_not_includes JournalEntry.column_names, "enrollment_id"
  end

  test "explicit client query orders dates and tied IDs and edits retain position" do
    client = User.find_by!(email: "client@healthie.example").client
    client.journal_entries.destroy_all
    old = client.journal_entries.create!(text: "old", created_at: 3.days.ago)
    first = client.journal_entries.create!(text: "first tie", created_at: 1.day.ago.change(usec: 0))
    second = client.journal_entries.create!(text: "second tie", created_at: first.created_at)
    expected = [ second.id, first.id, old.id ]
    assert_equal expected, client.journal_entries.order(created_at: :desc, id: :desc).pluck(:id)
    old.update!(text: "edited today")
    assert_equal expected, client.journal_entries.order(created_at: :desc, id: :desc).pluck(:id)
    empty = User.find_by!(email: "empty-client@healthie.example").client
    assert_empty empty.journal_entries.order(created_at: :desc, id: :desc)
  end

  test "journal seeds are repeatable with ties dates unrelated and empty clients" do
    ids = JournalEntry.order(:id).pluck(:id)
    Rails.application.load_seed
    assert_equal ids, JournalEntry.order(:id).pluck(:id)
    client = User.find_by!(email: "client@healthie.example").client
    entries = client.journal_entries.order(created_at: :desc, id: :desc).to_a
    assert_equal 3, entries.size
    assert_equal entries[0].created_at, entries[1].created_at
    assert_operator entries[0].id, :>, entries[1].id
    assert_operator entries[1].created_at, :>, entries[2].created_at
    assert_equal 1, User.find_by!(email: "unrelated-client@healthie.example").client.journal_entries.count
    assert_empty User.find_by!(email: "empty-client@healthie.example").client.journal_entries
  end
end
