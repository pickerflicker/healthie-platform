require "test_helper"
require_relative "../support/request_authentication"
require_relative "../support/domain_accounts"

class ProviderJournalsTest < ActionDispatch::IntegrationTest
  include DomainAccounts
  include RequestAuthentication

  setup do
    User.destroy_all
    @client = create_test_account("client", "Visible Client").client
  end

  test "provider navigation individual journals and feed show exactly current entries newest first" do
    other = create_test_account("client", "Unrelated Client").client
    provider = create_test_account("provider", "Enrolled Reader")
    @client.enrollments.create!(provider: provider.provider, plan: :premium)
    # Creation/ID order deliberately differs from date order; the newest date also ties.
    @client.journal_entries.create!(text: "Later visible entry", created_at: Time.utc(2026, 10, 19))
    entry = @client.journal_entries.create!(text: "Earlier visible entry", created_at: Time.utc(2026, 10, 17))
    @client.journal_entries.create!(text: "Tied later entry", created_at: Time.utc(2026, 10, 19))
    other_entry = other.journal_entries.create!(text: "Unrelated private entry")
    log_in_as(provider)
    get provider_home_path
    assert_select "a[href=?]", journal_entries_path, text: "Combined journal feed"
    get enrollments_path
    assert_select "a[href=?]", client_journal_entries_path(@client), text: /#{Regexp.escape(@client.name)}/
    [ journal_entries_path, client_journal_entries_path(@client) ].each do |path|
      get path
      assert_response :success
      assert_equal [ "Tied later entry", "Later visible entry", "Earlier visible entry" ], css_select("article").map { |node| node.css("p").last.text.strip }
      assert_no_match other_entry.text, response.body
      assert_select "a", text: "New journal entry", count: 0
    end
    get journal_entry_path(entry)
    assert_response :success
    assert_select "a", text: "Edit entry", count: 0
    assert_select "button", text: "Delete entry", count: 0
    get client_journal_entries_path(other)
    assert_response :not_found
    assert_no_match other.name, response.body
    get journal_entry_path(other_entry)
    assert_response :not_found
    get client_journal_entries_path(-1)
    assert_response :not_found
  end

  test "adding exposes historical entries and removing revokes reads and writes on the next request" do
    other = create_test_account("client", "Unrelated Client").client
    empty_provider = create_test_account("provider", "Unenrolled Reader")
    @entry = @client.journal_entries.create!(text: "Earlier visible entry", created_at: Time.utc(2026, 10, 17))
    later = @client.journal_entries.create!(text: "Later visible entry", created_at: Time.utc(2026, 10, 19))
    log_in_as(empty_provider)
    get journal_entries_path
    assert_response :success
    assert_select "article", count: 0
    assert_select "main", text: /No journal entries yet/
    get journal_entry_path(@entry)
    assert_response :not_found
    enrollment = @client.enrollments.create!(provider: empty_provider.provider, plan: :basic)
    # Keep this same User/Provider instance to expose accidental cached membership use.
    assert JournalEntryPolicy.new(empty_provider, @entry).show?
    assert ClientPolicy.new(empty_provider, @client).show?
    get client_journal_entries_path(@client)
    assert_response :success
    assert_select "article", count: 2
    get journal_entry_path(@entry)
    assert_response :success
    expected = [ [ @entry.id, @entry.text ], [ later.id, later.text ] ]
    enrollment.destroy!
    assert_equal false, JournalEntryPolicy.new(empty_provider, @entry).show?
    assert_equal false, ClientPolicy.new(empty_provider, @client).show?
    assert_empty ClientPolicy::Scope.new(empty_provider, Client.all).resolve
    assert_empty JournalEntryPolicy::Scope.new(empty_provider, JournalEntry.all).resolve
    get journal_entries_path
    assert_select "article", count: 0
    get client_journal_entries_path(@client)
    assert_unavailable_page
    [ journal_entry_path(@entry), edit_journal_entry_path(@entry) ].each do |path|
      get path
      assert_unavailable_page
    end
    assert_no_difference "JournalEntry.count" do
      patch journal_entry_path(@entry), params: { journal_entry: { text: "forged", client_id: other.id } }
      assert_unavailable_page
      delete journal_entry_path(@entry)
      assert_unavailable_page
    end
    assert_equal expected, @client.journal_entries.order(:id).pluck(:id, :text)
  end

  test "client individual listings conceal other clients and anonymous requests require sign in" do
    other = create_test_account("client", "Unrelated Client").client
    get client_journal_entries_path(@client)
    assert_redirected_to new_user_session_path
    log_in_as(@client.user)
    get client_journal_entries_path(@client)
    assert_response :success
    get client_journal_entries_path(other)
    assert_response :not_found
    assert_empty JournalEntryPolicy::Scope.new(nil, JournalEntry.all).resolve
    assert_empty ClientPolicy::Scope.new(nil, Client.all).resolve
  end

  private

  def assert_unavailable_page
    assert_response :not_found
    assert_select "main h1", text: "We couldn’t find that page."
    assert_select "main a[href=?]", root_path, text: "Return home"
    assert_no_match @entry.text, response.body
    assert_no_match @client.name, response.body
    assert_no_match "ActiveRecord::RecordNotFound", response.body
  end
end
