require "test_helper"

class EnrollmentsTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.load_seed
    @client = User.find_by!(email: "client@healthie.example")
    @other = User.find_by!(email: "unrelated-client@healthie.example")
    @provider = User.find_by!(email: "provider@healthie.example")
    @available = User.find_by!(email: "empty-provider@healthie.example").provider
    @enrollment = @client.client.enrollments.find_by!(provider: @provider.provider)
  end

  def login(user)
    post user_session_path, params: { user: { email: user.email, password: "Healthie-demo-2026" } }
  end

  test "client list and directory are scoped and Basic default or Premium add and remove work" do
    login(@client)
    get enrollments_path
    assert_response :success
    assert_select "tbody tr", count: 2
    assert_select "select[name='enrollment[provider_id]'] option", count: 1
    assert_select "option[selected][value=basic]"
    assert_match "existing and future journal entries", response.body
    journals = @client.client.journal_entries.order(:id).pluck(:id, :text)
    [ nil, "premium" ].each do |plan|
      input = { provider_id: @available.id, client_id: @other.client.id, user_id: @other.id }
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
    assert_not @other.client.enrollments.exists?(provider: @available)
  end

  test "duplicate invalid plan and unknown provider submissions do not write" do
    login(@client)
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
    login(@other)
    get enrollments_path
    assert_select "tbody tr", count: 1
    assert_no_difference "Enrollment.count" do
      delete enrollment_path(@enrollment)
      assert_response :not_found
    end
    delete destroy_user_session_path
    login(@provider)
    get enrollments_path
    assert_response :success
    assert_select "tbody tr", count: 2
    assert_match "Alex Rivera", response.body
    assert_match "Sam Chen", response.body
    assert_no_match "Jamie Brooks", response.body
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
      [ @other, @provider, nil ].each do |actor|
        assert_not EnrollmentPolicy.new(actor, @enrollment).public_send(action)
      end
    end
    assert_empty EnrollmentPolicy::Scope.new(nil, Enrollment.all).resolve
    assert_empty ProviderDirectoryPolicy::Scope.new(@provider, Provider.all).resolve
  end
end
