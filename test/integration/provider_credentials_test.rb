require "test_helper"
require_relative "../support/domain_accounts"
require_relative "../support/request_authentication"

class ProviderCredentialsRequestsTest < ActionDispatch::IntegrationTest
  include DomainAccounts
  include RequestAuthentication

  setup do
    @provider = create_test_account("provider", "Profile Owner").provider
    @other = create_test_account("provider", "Other Profile").provider
    @client = create_test_account("client", "Profile Client").client
  end

  test "owner edits multiple credentials clears them and sees meaningful invalid feedback" do
    log_in_as(@provider.user)
    get provider_home_path
    assert_select "a[href=?]", edit_provider_path
    get edit_provider_path
    assert_response :success
    assert_select "fieldset legend", text: "Credentials"
    assert_select "input[type=checkbox]", count: 6
    patch provider_home_path, params: { provider: { credentials: [ "", "LD", "RDN", "RDN" ] } }
    assert_redirected_to provider_home_path
    follow_redirect!
    assert_select "[role=status]", text: "Credentials saved."
    assert_includes response.body, "Welcome, Profile Owner, RDN, LD."
    assert_equal %w[RDN LD], @provider.reload.credentials
    get edit_provider_path
    assert_select "input[type=checkbox][checked]", count: 2
    patch provider_home_path, params: { provider: { credentials: [ "" ] } }
    follow_redirect!
    assert_includes response.body, "Welcome, Profile Owner."
    assert_equal [], @provider.reload.credentials

    [ [ "FAKE" ], "MD", { "MD" => "1" }, [ "MD", { "bad" => "value" } ] ].each do |invalid|
      patch provider_home_path, params: { provider: { credentials: invalid } }, as: :json
      assert_response :unprocessable_entity
      assert_select "[role=alert]", text: /Credentials.*supported selections/
      assert_equal [], @provider.reload.credentials
    end
  end

  test "anonymous and client requests are denied and policies independently deny other owners" do
    get edit_provider_path
    assert_redirected_to new_user_session_path
    patch provider_home_path, params: { provider: { credentials: [ "MD" ] } }
    assert_redirected_to new_user_session_path
    log_in_as(@client.user)
    get edit_provider_path
    assert_response :forbidden
    patch provider_home_path, params: { provider: { credentials: [ "MD" ], id: @provider.id } }
    assert_response :forbidden
    assert_equal [], @provider.reload.credentials
    %i[edit? update?].each do |action|
      assert ProviderPolicy.new(@provider.user, @provider).public_send(action)
      [ @other.user, @client.user, nil ].each do |actor|
        assert_not ProviderPolicy.new(actor, @provider).public_send(action)
      end
    end
  end

  test "forged ownership and unrelated fields reject the entire write" do
    log_in_as(@other.user)
    [ { id: @provider.id }, { user_id: @provider.user_id }, { provider_id: @provider.id },
      { name: "Changed identity" }, { role: "client" }, { user_attributes: { name: "Changed identity" } } ].each do |forgery|
      patch provider_home_path, params: { provider: forgery.merge(credentials: [ "MD" ]) }
      assert_response :unprocessable_entity
      assert_select "[role=alert]", text: /Only credentials/
      assert_equal [], @provider.reload.credentials
      assert_equal [], @other.reload.credentials
      assert_equal "Other Profile", @other.user.reload.name
      assert_equal "provider", @other.user.role
    end
    # A guessed record URL has no route; the singleton edit derives its owner from Devise.
    patch "/providers/#{@provider.id}", params: { provider: { credentials: [ "MD" ] } }
    assert_response :not_found
    assert_equal [], @provider.reload.credentials
  end

  test "client provider rows and selector display suffixes and blank names correctly" do
    @provider.update!(credentials: %w[LD RDN])
    @client.enrollments.create!(provider: @provider, plan: :premium)
    log_in_as(@client.user)
    get enrollments_path
    assert_select "tbody td", text: "Profile Owner, RDN, LD"
    assert_select "option", text: "Other Profile"
    @other.update!(credentials: %w[MD])
    get enrollments_path
    assert_select "option", text: "Other Profile, MD"
    assert_equal "Profile Owner", @provider.user.reload.name
    assert_equal "premium", @client.enrollments.sole.plan
  end
end
