require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup { Rails.application.load_seed }

  test "unauthenticated role pages require login" do
    [ root_path, provider_home_path, client_home_path ].each do |path|
      get path
      assert_redirected_to new_user_session_path
    end
  end

  test "invalid login shows meaningful failure" do
    post user_session_path, params: { user: { email: "client@healthie.example", password: "wrong" } }
    assert_response :unprocessable_entity
    assert_match "Invalid Email or password", response.body
  end

  test "both roles sign in navigate reject opposite access and sign out" do
    %w[provider client].each do |role|
      post user_session_path, params: { user: { email: "#{role}@healthie.example", password: "Healthie-demo-2026", role: role == "client" ? "provider" : "client" } }
      assert_redirected_to root_path
      follow_redirect!
      assert_redirected_to role == "client" ? client_home_path : provider_home_path
      follow_redirect!
      assert_response :success
      assert_select "h1", "#{role.titleize} home"
      get role == "client" ? provider_home_path : client_home_path
      assert_response :forbidden
      assert_match "Access denied", response.body
      assert_equal role, User.find_by!(email: "#{role}@healthie.example").role
      delete destroy_user_session_path
      assert_redirected_to root_path
      get role == "client" ? client_home_path : provider_home_path
      assert_redirected_to new_user_session_path
    end
  end

  test "account registration recovery and update routes are absent" do
    routes = Rails.application.routes.routes.map { |route| route.defaults[:action] if route.defaults[:controller].to_s.start_with?("devise/") }.compact
    assert_equal %w[create destroy new], routes.uniq.sort
  end

  test "profile scopes include only the signed in user's matching profile" do
    provider = User.find_by!(role: "provider")
    client = User.find_by!(role: "client")
    other = User.create_account!(name: "Other", email: "other@example.com", password: "test-password-123", role: "client")
    assert_equal [ client.client ], ClientPolicy::Scope.new(client, Client.all).resolve.to_a
    assert_empty ClientPolicy::Scope.new(provider, Client.all).resolve
    assert_equal [ provider.provider ], ProviderPolicy::Scope.new(provider, Provider.all).resolve.to_a
    assert_empty ProviderPolicy::Scope.new(client, Provider.all).resolve
    assert_not_includes ClientPolicy::Scope.new(client, Client.all).resolve, other.client
  end
end
