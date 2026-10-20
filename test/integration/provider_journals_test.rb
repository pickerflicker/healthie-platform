require "test_helper"

class ProviderJournalsTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.load_seed
    @client = User.find_by!(email: "client@healthie.example").client
    @other = User.find_by!(email: "unrelated-client@healthie.example").client
    @provider = User.find_by!(email: "second-provider@healthie.example")
    @empty_provider = User.find_by!(email: "empty-provider@healthie.example")
    @entry = @client.journal_entries.order(:id).first
  end

  def login(user)
    delete destroy_user_session_path
    post user_session_path, params: { user: { email: user.email, password: "Healthie-demo-2026" } }
  end

  test "provider navigation individual journals and feed show exactly current entries newest first" do
    login(@provider)
    get provider_home_path
    assert_select "a[href=?]", journal_entries_path, text: "Combined journal feed"
    get enrollments_path
    assert_select "a[href=?]", client_journal_entries_path(@client), text: @client.name
    [ journal_entries_path, client_journal_entries_path(@client) ].each do |path|
      get path
      assert_response :success
      assert_equal @client.journal_entries.order(created_at: :desc, id: :desc).map(&:text), css_select("article").map { |node| node.css("p").last.text.strip }
      assert_no_match @other.journal_entries.first.text, response.body
      assert_select "a", text: "New journal entry", count: 0
    end
    get journal_entry_path(@entry)
    assert_response :success
    assert_select "a", text: "Edit entry", count: 0
    assert_select "button", text: "Delete entry", count: 0
    get client_journal_entries_path(@other)
    assert_response :not_found
    assert_no_match @other.name, response.body
    get journal_entry_path(@other.journal_entries.first)
    assert_response :not_found
    get client_journal_entries_path(-1)
    assert_response :not_found
  end

  test "adding exposes historical entries and removing revokes reads and writes on the next request" do
    login(@empty_provider)
    get journal_entries_path
    assert_response :success
    assert_select "article", count: 0
    assert_select "main", text: /No journal entries yet/
    get journal_entry_path(@entry)
    assert_response :not_found
    enrollment = @client.enrollments.create!(provider: @empty_provider.provider, plan: :basic)
    # Keep this same User/Provider instance to expose accidental cached membership use.
    assert JournalEntryPolicy.new(@empty_provider, @entry).show?
    assert ClientPolicy.new(@empty_provider, @client).show?
    get client_journal_entries_path(@client)
    assert_response :success
    assert_select "article", count: 3
    get journal_entry_path(@entry)
    assert_response :success
    expected = @client.journal_entries.order(:id).pluck(:id, :text)
    enrollment.destroy!
    assert_equal false, JournalEntryPolicy.new(@empty_provider, @entry).show?
    assert_equal false, ClientPolicy.new(@empty_provider, @client).show?
    assert_empty ClientPolicy::Scope.new(@empty_provider, Client.all).resolve
    assert_empty JournalEntryPolicy::Scope.new(@empty_provider, JournalEntry.all).resolve
    get journal_entries_path
    assert_select "article", count: 0
    get client_journal_entries_path(@client)
    assert_unavailable_page
    [ journal_entry_path(@entry), edit_journal_entry_path(@entry) ].each do |path|
      get path
      assert_unavailable_page
    end
    assert_no_difference "JournalEntry.count" do
      patch journal_entry_path(@entry), params: { journal_entry: { text: "forged", client_id: @other.id } }
      assert_unavailable_page
      delete journal_entry_path(@entry)
      assert_unavailable_page
    end
    assert_equal expected, @client.journal_entries.order(:id).pluck(:id, :text)
  end

  test "client individual listings conceal other clients and anonymous requests require sign in" do
    get client_journal_entries_path(@client)
    assert_redirected_to new_user_session_path
    login(@client.user)
    get client_journal_entries_path(@client)
    assert_response :success
    get client_journal_entries_path(@other)
    assert_response :not_found
    assert_empty JournalEntryPolicy::Scope.new(nil, JournalEntry.all).resolve
    assert_empty ClientPolicy::Scope.new(nil, Client.all).resolve
  end

  private

  def assert_unavailable_page
    assert_response :not_found
    assert_select "main h1", text: "Page not found"
    assert_select "main a[href=?]", root_path, text: "Return home"
    assert_no_match @entry.text, response.body
    assert_no_match @client.name, response.body
    assert_no_match "ActiveRecord::RecordNotFound", response.body
  end
end
