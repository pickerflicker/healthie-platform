require "test_helper"

class AccountTest < ActiveSupport::TestCase
  setup { User.destroy_all }

  def account(role = "client", email = "alex@example.com")
    User.create_account!(name: "Alex", email: email, password: "test-password-123", role: role)
  end

  test "each role creates exactly its matching profile with delegated identity" do
    %w[provider client].each do |role|
      user = account(role, "#{role}@example.com")
      profile = user.public_send(role)
      assert profile.persisted?
      assert_equal user.name, profile.name
      assert_equal user.email, profile.email
      assert_equal role, user.reload.role
      assert_nil user.public_send(role == "client" ? :provider : :client)
    end
  end

  test "identity and exactly one matching profile are required" do
    assert_not User.new.valid?
    assert_not User.new(name: "Alex", email: "alex@example.com", password: "test-password-123", role: "client").valid?
    user = User.new(name: "Alex", email: "alex@example.com", password: "test-password-123", role: "client")
    user.build_provider
    assert_not user.valid?
    user.build_client
    assert_not user.valid?
    assert_raises(ActiveRecord::RecordInvalid) { account("admin") }
    assert_equal 0, User.count
  end

  test "duplicate identity and profiles fail without partial accounts" do
    user = account
    assert_raises(ActiveRecord::RecordInvalid) { account("provider", user.email.upcase) }
    assert_not Client.new(user: user).valid?
    assert_not Provider.new(user: user).valid?
    assert_equal 1, User.count
    assert_equal 1, Client.count
    assert_equal 0, Provider.count
    assert_raises(ActiveRecord::RecordNotUnique) do
      Client.transaction(requires_new: true) { Client.insert_all!([ { user_id: user.id } ]) }
    end
    assert_raises(ActiveRecord::NotNullViolation) do
      Client.transaction(requires_new: true) { Client.insert_all!([ { user_id: nil } ]) }
    end
    assert_raises(ActiveRecord::InvalidForeignKey) do
      Client.transaction(requires_new: true) { Client.insert_all!([ { user_id: -1 } ]) }
    end
  end

  test "profile persistence failure rolls back parent save" do
    user = User.new(name: "Alex", email: "rollback@example.com", password: "test-password-123", role: "client")
    user.build_client
    user.client.define_singleton_method(:save) { |**| raise ActiveRecord::RecordInvalid, self }
    assert_raises(ActiveRecord::RecordInvalid) { user.save! }
    assert_not User.exists?(email: "rollback@example.com")
    assert_equal 0, Client.count
  end

  test "role and required profile cannot be changed or removed" do
    user = account
    assert_not user.update(role: "provider")
    other = account("client", "other@example.com")
    assert_not user.client.update(user: other)
    assert_not user.client.reload.destroy
    assert user.reload.client
    assert user.destroy
    assert_equal 1, Client.count
  end
end
