require "test_helper"
require_relative "../support/request_authentication"
require_relative "../support/domain_accounts"

class EnrollmentsTest < ActionDispatch::IntegrationTest
  include DomainAccounts
  include RequestAuthentication

  setup do
    User.destroy_all
    @client = create_test_account("client", "Relationship Client")
    @provider = create_test_account("provider", "Current Provider")
    @available = create_test_account("provider", "Available Provider").provider
    @enrollment = @client.client.enrollments.create!(provider: @provider.provider)
  end

  test "client list and directory are scoped and Basic default or Premium add and remove work" do
    other = create_test_account("client", "Other Client")
    second = create_test_account("provider", "Second Provider")
    @client.client.enrollments.create!(provider: second.provider, plan: :premium)
    entry = @client.client.journal_entries.create!(text: "Retain this entry after removal")
    log_in_as(@client)
    get enrollments_path
    assert_response :success
    assert_select "tbody tr", count: 2
    assert_select "select[name='enrollment[provider_id]'] option", count: 1
    assert_select "option[selected][value=basic]"
    assert_match "existing and future journal entries", response.body
    journals = [ [ entry.id, entry.text ] ]
    [ nil, "premium" ].each do |plan|
      input = { provider_id: @available.id, client_id: other.client.id, user_id: other.id }
      input[:plan] = plan if plan
      assert_difference "Enrollment.count", 1 do
        post enrollments_path, params: { enrollment: input }
      end
      assert_response :see_other
      enrollment = @client.client.enrollments.find_by!(provider: @available)
      assert_equal plan || "basic", enrollment.plan
      follow_redirect!
      assert_no_match "<select", response.body
      assert_select "tbody tr", count: 3
      delete enrollment_path(enrollment)
      assert_response :see_other
    end
    assert_equal journals, @client.client.journal_entries.order(:id).pluck(:id, :text)
    assert_not other.client.enrollments.exists?(provider: @available)
  end

  test "duplicate invalid plan and unknown provider submissions do not write" do
    log_in_as(@client)
    assert_no_difference "Enrollment.count" do
      post enrollments_path, params: { enrollment: { provider_id: @provider.provider.id, plan: "premium" } }
      assert_response :unprocessable_entity
      assert_match "already enrolled", response.body
      post enrollments_path, params: { enrollment: { provider_id: @available.id, plan: "gold" } }
      assert_response :unprocessable_entity
      assert_match "Plan is not included", response.body
      post enrollments_path, params: { enrollment: { provider_id: -1 } }
      assert_response :not_found
    end
  end

  test "other clients relationships are concealed and provider mutation requests are forbidden" do
    other = create_test_account("client", "Other Client")
    unrelated = create_test_account("client", "Unrelated Client")
    second = create_test_account("provider", "Second Provider")
    @client.client.enrollments.create!(provider: second.provider, plan: :premium)
    other.client.enrollments.create!(provider: @provider.provider)
    log_in_as(other)
    get enrollments_path
    assert_select "tbody tr", count: 1
    assert_no_difference "Enrollment.count" do
      delete enrollment_path(@enrollment)
      assert_response :not_found
    end
    log_out
    log_in_as(@provider)
    get enrollments_path
    assert_response :success
    assert_select "tbody tr", count: 2
    assert_match @client.name, response.body
    assert_match other.name, response.body
    assert_no_match unrelated.name, response.body
    assert_select "form[action^='/enrollments']", count: 0
    assert_no_difference "Enrollment.count" do
      post enrollments_path, params: { enrollment: { client_id: @client.client.id, provider_id: @available.id } }
      assert_response :forbidden
      delete enrollment_path(@enrollment)
      assert_response :forbidden
      delete enrollment_path(@client.client.enrollments.find_by!(plan: "premium"))
      assert_response :not_found
    end
  end

  test "anonymous endpoints require sign in and policies independently check ownership" do
    other = create_test_account("client", "Other Client")
    get enrollments_path
    assert_redirected_to new_user_session_path
    assert_no_difference "Enrollment.count" do
      post enrollments_path, params: { enrollment: { provider_id: @available.id } }
      assert_redirected_to new_user_session_path
      delete enrollment_path(@enrollment)
      assert_redirected_to new_user_session_path
    end
    %i[create? destroy?].each do |action|
      assert EnrollmentPolicy.new(@client, @enrollment).public_send(action)
      [ other, @provider, nil ].each do |actor|
        assert_not EnrollmentPolicy.new(actor, @enrollment).public_send(action)
      end
    end
    assert_empty EnrollmentPolicy::Scope.new(nil, Enrollment.all).resolve
    assert_empty ProviderDirectoryPolicy::Scope.new(@provider, Provider.all).resolve
  end
end
