require "test_helper"

class JournalEntriesTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.load_seed
    @owner = User.find_by!(email: "client@healthie.example")
    @other = User.find_by!(email: "unrelated-client@healthie.example")
    @entry = @owner.client.journal_entries.first
    @foreign = @other.client.journal_entries.first
  end

  def login(user)
    post user_session_path, params: { user: { email: user.email, password: "Healthie-demo-2026" } }
  end

  test "owner CRUD persists text only and scoped listing excludes others" do
    login(@owner)
    get journal_entries_path
    assert_response :success
    assert_select "article", count: 3
    assert_no_match @foreign.text, response.body
    get new_journal_entry_path
    assert_response :success
    assert_difference "JournalEntry.count", 1 do
      post journal_entries_path, params: { journal_entry: { text: "New <script>note</script>\nsecond line", client_id: @other.client.id, created_at: "2000-01-01" } }
    end
    entry = JournalEntry.order(:id).last
    assert_equal @owner.client.id, entry.client_id
    assert_operator entry.created_at, :>, Time.utc(2026)
    follow_redirect!
    assert_response :success
    assert_no_match "<script>note</script>", response.body
    get edit_journal_entry_path(entry)
    assert_response :success
    created = entry.created_at
    patch journal_entry_path(entry), params: { journal_entry: { text: "Edited", client_id: @other.client.id, created_at: "2000-01-01" } }
    assert_response :see_other
    assert_equal "Edited", entry.reload.text
    assert_equal @owner.client.id, entry.client_id
    assert_equal created, entry.created_at
    assert_difference "JournalEntry.count", -1 do
      delete journal_entry_path(entry)
    end
    assert_redirected_to journal_entries_path
  end

  test "blank create and update render validation errors without changing records" do
    login(@owner)
    assert_no_difference "JournalEntry.count" do
      post journal_entries_path, params: { journal_entry: { text: " " } }
    end
    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /Text can't be blank/
    original = @entry.text
    patch journal_entry_path(@entry), params: { journal_entry: { text: "" } }
    assert_response :unprocessable_entity
    assert_equal original, @entry.reload.text
  end

  test "foreign records and guessed IDs are concealed for direct reads and writes" do
    login(@other)
    [ @entry.id, -1 ].each do |id|
      get journal_entry_path(id)
      assert_response :not_found
      assert_no_match @entry.text, response.body
      get edit_journal_entry_path(id)
      assert_response :not_found
      patch journal_entry_path(id), params: { journal_entry: { text: "stolen", client_id: @other.client.id } }
      assert_response :not_found
      assert_no_difference "JournalEntry.count" do
        delete journal_entry_path(id)
        assert_response :not_found
      end
    end
    assert_not_equal "stolen", @entry.reload.text
  end

  test "providers cannot list create read edit update or delete client journals" do
    login(User.find_by!(email: "provider@healthie.example"))
    get journal_entries_path
    assert_response :forbidden
    get new_journal_entry_path
    assert_response :forbidden
    assert_no_difference "JournalEntry.count" do
      post journal_entries_path, params: { journal_entry: { text: "forged", client_id: @owner.client.id } }
      assert_response :forbidden
      get journal_entry_path(@entry)
      assert_response :not_found
      get edit_journal_entry_path(@entry)
      assert_response :not_found
      patch journal_entry_path(@entry), params: { journal_entry: { text: "forged" } }
      assert_response :not_found
      delete journal_entry_path(@entry)
      assert_response :not_found
    end
    assert_not_equal "forged", @entry.reload.text
  end

  test "all journal endpoints require authentication" do
    [ journal_entries_path, new_journal_entry_path, journal_entry_path(@entry), edit_journal_entry_path(@entry) ].each do |path|
      get path
      assert_redirected_to new_user_session_path
    end
    assert_no_difference "JournalEntry.count" do
      post journal_entries_path, params: { journal_entry: { text: "anonymous" } }
      assert_redirected_to new_user_session_path
      patch journal_entry_path(@entry), params: { journal_entry: { text: "anonymous" } }
      assert_redirected_to new_user_session_path
      delete journal_entry_path(@entry)
      assert_redirected_to new_user_session_path
    end
    assert_not_equal "anonymous", @entry.reload.text
  end

  test "instance policies independently enforce ownership and role" do
    provider = User.find_by!(email: "provider@healthie.example")
    %i[show? edit? update? destroy? create? new?].each do |action|
      assert JournalEntryPolicy.new(@owner, @entry).public_send(action)
      [ @other, provider, nil ].each do |user|
        assert_not JournalEntryPolicy.new(user, @entry).public_send(action)
      end
    end
    assert_equal @owner.client.journal_entries.order(:id).pluck(:id), JournalEntryPolicy::Scope.new(@owner, JournalEntry.all).resolve.order(:id).pluck(:id)
    assert_empty JournalEntryPolicy::Scope.new(provider, JournalEntry.all).resolve
  end
end
