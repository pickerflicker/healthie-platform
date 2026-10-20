require "test_helper"

class EnrollmentOrderTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false

  setup do
    @users = []
    @provider = account("provider").provider
    @client = account("client").client
    @providers = 3.times.map { account("provider").provider }
    @clients = 3.times.map { account("client").client }
    # Higher enrollment ID is deliberately older, while two relationships tie.
    times = [ Time.utc(2026, 10, 19), Time.utc(2026, 10, 19), Time.utc(2026, 10, 18) ]
    @forward = @clients.zip(times).map { |client, time| @provider.enrollments.create!(client: client, created_at: time) }
    @reverse = @providers.zip(times).map { |provider, time| @client.enrollments.create!(provider: provider, created_at: time) }
  end

  teardown do
    @users.reverse_each(&:destroy!)
  end

  test "both associations and pages order relationships rather than profiles with deterministic ties" do
    expected_clients = [ @clients[1].id, @clients[0].id, @clients[2].id ]
    expected_providers = [ @providers[1].id, @providers[0].id, @providers[2].id ]
    assert_equal expected_clients, @provider.clients.pluck(:id)
    assert_equal expected_providers, @client.providers.pluck(:id)
    assert_equal expected_providers, @client.provider_list.pluck(:provider_id)
    assert_equal expected_providers, @client.provider_list.pluck(:provider_id), "warm cache parity"
    @providers[2].user.update!(name: "Edited old relationship")
    @clients[2].user.update!(name: "Edited client")
    assert_equal expected_clients, @provider.clients.pluck(:id)
    assert_equal expected_providers, @client.provider_list.pluck(:provider_id)

    [ [ @provider.user, @clients.values_at(1, 0, 2).map(&:name) ],
      [ @client.user, @providers.values_at(1, 0, 2).map(&:name) ] ].each do |user, names|
      post user_session_path, params: { user: { email: user.email, password: "Healthie-demo-2026" } }
      get enrollments_path
      assert_response :success
      assert_select "tbody tr td:first-child", text: /./, count: 3
      assert_equal names, css_select("tbody tr td:first-child").map { |cell| cell.text.strip }
      delete destroy_user_session_path
    end

    @forward[2].destroy!
    @reverse[2].destroy!
    @provider.enrollments.create!(client: @clients[2])
    @client.enrollments.create!(provider: @providers[2])
    assert_equal expected_clients.rotate(-1), @provider.clients.pluck(:id)
    assert_equal expected_providers.rotate(-1), @client.provider_list.pluck(:provider_id)
    empty = account("client").client
    assert_empty empty.providers
    assert_empty empty.provider_list
    empty.enrollments.create!(provider: @provider)
    assert_equal [ @provider.id ], empty.providers.pluck(:id)
    assert_equal [ @provider.id ], empty.provider_list.pluck(:provider_id)
    lone = account("provider").provider
    assert_empty lone.clients
    lone.enrollments.create!(client: empty)
    assert_equal [ empty.id ], lone.clients.pluck(:id)
  end

  test "uncached lists preload names and emails and cold and warm display caches bound User queries" do
    ActiveRecord::Base.uncached do
      [ @provider.clients, @client.providers,
        EnrollmentPolicy::Scope.new(@provider.user, Enrollment.all).resolve.preload(client: :user).newest_first ].each do |relation|
        rows = relation.to_a
        queries = user_selects do
          rows.each do |row|
            profile = row.is_a?(Enrollment) ? row.client : row
            assert profile.name.present?
            assert profile.email.present?
          end
        end
        assert_empty queries, "reading displayed identities after loading must issue no User SELECTs"
      end
      Rails.cache.delete(Client.provider_list_cache_key(@client.id))
      cold = user_selects { assert_equal 3, @client.provider_list.size }
      assert_equal 1, cold.size, "cold cache loads all provider users together"
      warm = user_selects { assert_equal 3, @client.provider_list.size }
      assert_empty warm, "warm cache contains serializable display values"
    end
  end

  private

  def user_selects
    queries = []
    callback = ->(event) { queries << event.payload[:sql] if event.payload[:sql].match?(/SELECT.*FROM "users"/m) }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
    queries
  end

  def account(role)
    number = @users.size
    User.create_account!(name: "Ordering #{number}", email: "ordering-#{SecureRandom.hex(6)}@healthie.example",
      password: "Healthie-demo-2026", role: role).tap do |user|
      # Older profiles can acquire newer relationships; edits must not move them.
      user.public_send(role).update_columns(created_at: Time.utc(2020, 1, 1) + number.days)
      @users << user
    end
  end
end
