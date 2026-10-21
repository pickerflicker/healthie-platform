require "test_helper"
require_relative "../support/request_authentication"
require_relative "../support/domain_accounts"

class AuthenticationTest < ActionDispatch::IntegrationTest
  include DomainAccounts
  include RequestAuthentication

  setup { User.destroy_all }

  test "unauthenticated role pages require login" do
    [ root_path, provider_home_path, client_home_path ].each do |path|
      get path
      assert_redirected_to new_user_session_path
    end
  end

  test "invalid login shows meaningful failure" do
    client = create_test_account("client", "Test Client")
    post user_session_path, params: { user: { email: client.email, password: "wrong" } }
    assert_response :unprocessable_entity
    assert_select '[role="alert"]', text: /\AInvalid email or password\.\z/i
  end

  test "both roles sign in navigate reject opposite access and sign out" do
    client = create_test_account("client", "Test Client")
    provider = create_test_account("provider", "Test Provider")
    [ provider, client ].each do |account|
      role = account.role
      post user_session_path, params: { user: { email: account.email, password: DomainAccounts::PASSWORD, role: role == "client" ? "provider" : "client" } }
      assert_redirected_to root_path
      follow_redirect!
      assert_redirected_to role == "client" ? client_home_path : provider_home_path
      follow_redirect!
      assert_response :success
      assert_select "h1", "#{role.titleize} home"
      get role == "client" ? provider_home_path : client_home_path
      assert_response :forbidden
      assert_match "Access denied", response.body
      assert_equal role, account.reload.role
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

  test "profile scopes include own profile and current provider clients only" do
    client = create_test_account("client", "Test Client")
    provider = create_test_account("provider", "Test Provider")
    client.client.enrollments.create!(provider: provider.provider)
    other = create_test_account("client", "Other", email: "other@example.com")
    assert_equal [ client.client ], ClientPolicy::Scope.new(client, Client.all).resolve.to_a
    assert_equal [ client.client.id ], ClientPolicy::Scope.new(provider, Client.all).resolve.order(:id).pluck(:id)
    assert_equal [ provider.provider ], ProviderPolicy::Scope.new(provider, Provider.all).resolve.to_a
    assert_empty ProviderPolicy::Scope.new(client, Provider.all).resolve
    assert_not_includes ClientPolicy::Scope.new(client, Client.all).resolve, other.client
  end

  test "client policy independently enforces record ownership and role" do
    client = create_test_account("client", "Test Client")
    provider = create_test_account("provider", "Test Provider")
    client.client.enrollments.create!(provider: provider.provider)
    other = create_test_account("client", "Other", email: "other@example.com")

    assert ClientPolicy.new(client, client.client).show?
    assert_not ClientPolicy.new(client, other.client).show?
    assert_not ClientPolicy.new(other, client.client).show?
    assert ClientPolicy.new(provider, client.client).show?
    assert_not ClientPolicy.new(provider, other.client).show?
    assert_not ClientPolicy.new(nil, client.client).show?
  end

  test "client home authorizes own loaded profile despite forged record parameters" do
    client = create_test_account("client", "Test Client")
    other = create_test_account("client", "Other", email: "other@example.com")
    log_in_as(client)

    get client_home_path, params: { id: other.client.id, client_id: other.client.id, user_id: other.id, role: "provider" }
    assert_response :success
    assert_select "h1", "Client home"
    assert_select "main", text: /#{Regexp.escape(client.name)}/
    assert_select "main", text: /#{Regexp.escape(client.email)}/
    assert_select "main", text: /other@example.com/, count: 0
  end

  test "provider policy independently enforces record ownership and role" do
    client = create_test_account("client", "Test Client")
    provider = create_test_account("provider", "Test Provider")
    other = create_test_account("provider", "Other Provider", email: "other-provider@example.com")

    assert ProviderPolicy.new(provider, provider.provider).show?
    assert_not ProviderPolicy.new(provider, other.provider).show?
    assert_not ProviderPolicy.new(other, provider.provider).show?
    assert_not ProviderPolicy.new(client, provider.provider).show?
    assert_not ProviderPolicy.new(nil, provider.provider).show?
  end

  test "provider home authorizes own loaded profile despite forged record parameters" do
    provider = create_test_account("provider", "Test Provider")
    other = create_test_account("provider", "Other Provider", email: "other-provider@example.com")
    log_in_as(provider)

    get provider_home_path, params: { id: other.provider.id, provider_id: other.provider.id, user_id: other.id, role: "client" }
    assert_response :success
    assert_select "h1", "Provider home"
    assert_select "main", text: /#{Regexp.escape(provider.name)}/
    assert_select "main", text: /#{Regexp.escape(provider.email)}/
    assert_select "main", text: /other-provider@example.com/, count: 0
  end
end
