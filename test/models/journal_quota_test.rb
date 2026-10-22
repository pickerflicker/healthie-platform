require "test_helper"
require_relative "../support/domain_accounts"

class JournalQuotaTest < ActiveSupport::TestCase
  include DomainAccounts

  setup do
    @client = create_test_account("client", "Quota Client").client
    @provider = create_test_account("provider", "Quota Provider").provider
    @enrollment = @client.enrollments.create!(provider: @provider, plan: :basic)
    travel_to Time.zone.local(2026, 10, 31, 23, 59, 59)
  end

  teardown { travel_back }

  test "basic boundaries and all normal save paths revalidate under the limit" do
    stale = JournalEntry.new(client: @client, provider: @provider, text: "Previously valid")
    assert stale.valid?
    first = create_entry
    assert_equal 1, @client.journal_entries.count
    8.times { create_entry }
    assert_equal 9, @client.journal_entries.count
    tenth = @client.journal_entries.create(provider: @provider, text: "tenth")
    assert tenth.persisted?
    assert_not stale.save(context: :custom), "Custom validation context cannot skip the cap"
    assert_not stale.save, "valid? must not reserve a slot"
    assert_not @client.journal_entries.create(provider: @provider, text: "eleventh").persisted?
    assert_raises(ActiveRecord::RecordInvalid) { create_entry }
    assert_raises(ActiveRecord::RecordInvalid) { stale.save! }
    assert_equal 10, @client.journal_entries.count
    assert tenth.update(text: "Still editable at ten")
    first.destroy!
    assert create_entry.persisted?
    assert_equal 10, @client.journal_entries.count
  end

  test "inclusive month start exclusive next month and rollover use application time" do
    # Build legitimate history at its actual application time, plus a future row.
    travel_to Time.zone.local(2026, 9, 30, 23, 59, 59)
    10.times { create_entry }
    travel_to Time.zone.local(2026, 11, 1)
    10.times { create_entry }
    travel_to Time.zone.local(2026, 10, 1)
    first = create_entry
    assert_equal Time.zone.local(2026, 10, 1), first.created_at
    travel_to Time.zone.local(2026, 10, 31, 23, 59, 59)
    9.times { create_entry }
    assert_not JournalEntry.new(client: @client, provider: @provider, text: "blocked").valid?
    stale = JournalEntry.new(client: @client, provider: @provider, text: "Validate before rollover")
    assert_not stale.valid?
    travel_to Time.zone.local(2026, 12, 1)
    assert stale.save
    assert_equal Time.current, stale.created_at
    assert create_entry.persisted?
  end

  test "pair buckets premium downgrade and remove re-add preserve usage and history" do
    other_provider = create_test_account("provider", "Independent Provider").provider
    other_client = create_test_account("client", "Independent Client").client
    @client.enrollments.create!(provider: other_provider, plan: :basic)
    other_client.enrollments.create!(provider: @provider, plan: :basic)
    10.times { create_entry }
    assert @client.journal_entries.create!(provider: other_provider, text: "Independent provider").persisted?
    assert other_client.journal_entries.create!(provider: @provider, text: "Independent client").persisted?
    @enrollment.update!(plan: :premium)
    3.times { create_entry }
    @enrollment.update!(plan: :basic)
    assert_raises(ActiveRecord::RecordInvalid) { create_entry }
    @enrollment.destroy!
    assert_raises(ActiveRecord::RecordInvalid) { create_entry }
    @client.enrollments.create!(provider: @provider, plan: :basic)
    assert_raises(ActiveRecord::RecordInvalid) { create_entry }
    assert_equal 13, @client.journal_entries.where(provider: @provider).count
  end

  test "new entries require enrollment and immutable ownership while legacy history stays editable" do
    unrelated = create_test_account("provider", "Unenrolled Provider").provider
    [ nil, unrelated ].each do |provider|
      entry = @client.journal_entries.new(provider: provider, text: "ineligible")
      assert_not entry.save
      assert entry.errors[:provider].any?
    end
    entry = create_entry
    [ { provider_id: unrelated.id }, { client_id: -1 }, { created_at: 1.day.ago } ].each do |attributes|
      assert_not entry.update(attributes)
      assert entry.errors.any?
      entry.reload
    end
    assert_raises(ActiveRecord::InvalidForeignKey) do
      Provider.transaction(requires_new: true) { Provider.where(id: @provider.id).delete_all }
    end
    JournalEntry.insert_all!([ { client_id: @client.id, text: "Legacy private history" } ])
    legacy = @client.journal_entries.find_by!(provider_id: nil)
    assert legacy.update(text: "Legacy edited")
    assert JournalEntryPolicy.new(@client.user, legacy).show?
    assert_not JournalEntryPolicy.new(@provider.user, legacy).show?
    assert_not_includes JournalEntryPolicy::Scope.new(@provider.user, JournalEntry.all).resolve, legacy
  end

  private

  def create_entry
    JournalEntry.create!(client: @client, provider: @provider, text: "Quota note")
  end
end
