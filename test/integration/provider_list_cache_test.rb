require "test_helper"
require_relative "../support/request_authentication"
require "redis"
require_relative "../support/domain_accounts"

class ProviderListCacheTest < ActionDispatch::IntegrationTest
  include DomainAccounts
  include RequestAuthentication

  # Real commits are essential: transactional tests cannot prove after_commit.
  self.use_transactional_tests = false

  setup do
    @users = []
    @client = account("cache-client", "client").client
    @other = account("cache-other", "client").client
    @provider = account("cache-provider", "provider").provider
    @extra = account("cache-extra", "provider").provider
    @enrollment = @client.enrollments.create!(provider: @provider, plan: :basic)
  end

  teardown do
    @users.reverse_each(&:destroy!)
    [ @client, @other ].each { |client| Rails.cache.delete(Client::ProviderList.cache_key(client.id)) }
  end

  test "Redis miss queries once and hit reuses serializable rows with client isolation" do
    queries = []
    events = []
    sql = ->(event) { queries << event.payload[:sql] if event.payload[:sql].match?(/SELECT.*FROM "enrollments"/m) }
    cache = ->(event) { events << event.name }
    ActiveSupport::Notifications.subscribed(sql, "sql.active_record") do
      ActiveSupport::Notifications.subscribed(cache, /cache_(generate|fetch_hit)\.active_support/) do
        assert_equal [ { enrollment_id: @enrollment.id, provider_id: @provider.id, name: "cache-provider", plan: "basic", credentials: [] } ], @client.provider_list
        assert_equal 1, queries.length
        assert_equal @client.provider_list, @client.provider_list
        assert_equal 1, queries.length, "Redis hits must not rerun the provider-list query"
      end
    end
    assert_includes events, "cache_generate.active_support"
    assert_includes events, "cache_fetch_hit.active_support"
    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://127.0.0.1:56379/0"))
    redis_key = "healthie:test:#{Client::ProviderList.cache_key(@client.id)}"
    assert redis.exists?(redis_key)
    assert_includes 1..60, redis.ttl(redis_key), "Provider-list entries must expire within one minute of writing"
    assert_empty @other.provider_list
    assert_equal [ @provider.id ], @client.provider_list.pluck(:provider_id)
    assert_equal [ @provider.id ], @client.providers.pluck(:id), "raw association remains available"
  end

  test "committed add remove and plan changes invalidate only the affected client" do
    original = @client.provider_list
    @other.provider_list
    other_key = Client::ProviderList.cache_key(@other.id)
    Enrollment.transaction do
      @enrollment.destroy!
      raise ActiveRecord::Rollback
    end
    assert_equal original, Rails.cache.read(Client::ProviderList.cache_key(@client.id))
    assert_equal original, @client.provider_list
    extra = @client.enrollments.create!(provider: @extra, plan: :premium)
    assert_nil Rails.cache.read(Client::ProviderList.cache_key(@client.id))
    assert_equal [], Rails.cache.read(other_key)
    assert_equal [ @extra.id, @provider.id ], @client.provider_list.pluck(:provider_id)
    @enrollment.update!(plan: :premium)
    assert_equal %w[premium premium], @client.provider_list.pluck(:plan)
    extra.destroy!
    assert_nil Rails.cache.read(Client::ProviderList.cache_key(@client.id))
    assert_equal [ @provider.id ], @client.provider_list.pluck(:provider_id)
    @enrollment.destroy!
    assert_empty @client.provider_list
    assert_equal [], Rails.cache.read(other_key)
  end

  test "provider name commits invalidate every enrolled client and rollback preserves display" do
    @other.enrollments.create!(provider: @provider)
    [ @client, @other ].each(&:provider_list)
    User.transaction do
      @provider.user.update!(name: "Rolled back")
      raise ActiveRecord::Rollback
    end
    assert_equal [ "cache-provider" ], @client.provider_list.pluck(:name)
    User.transaction do
      @provider.user.reload.update!(name: "Renamed provider")
      @provider.user.update!(password: "Another-password-2026")
    end
    [ @client, @other ].each do |client|
      assert_nil Rails.cache.read(Client::ProviderList.cache_key(client.id))
      assert_equal [ "Renamed provider" ], client.provider_list.pluck(:name)
    end
  end

  test "credential commits refresh all enrolled clients while failures rollback and unrelated caches stay intact" do
    @other.enrollments.create!(provider: @provider)
    unrelated = account("cache-unrelated", "client").client
    unrelated.enrollments.create!(provider: @extra)
    original = @client.provider_list
    @other.provider_list
    isolated = unrelated.provider_list
    key = Client::ProviderList.cache_key(@client.id)
    assert_not @provider.update(credentials: %w[MD FAKE])
    assert_equal original, Rails.cache.read(key)
    Provider.transaction do
      @provider.reload.update!(credentials: %w[MD])
      assert_equal original, Rails.cache.read(key), "Do not publish uncommitted changes"
      raise ActiveRecord::Rollback
    end
    assert_equal original, Rails.cache.read(key)
    assert_equal [], @provider.reload.credentials
    Provider.transaction do
      @provider.update!(credentials: %w[LD RDN])
      @provider.touch # A later save must not hide the credential change at commit.
      assert_equal original, Rails.cache.read(key)
    end
    [ @client, @other ].each do |client|
      assert_nil Rails.cache.read(Client::ProviderList.cache_key(client.id))
      assert_equal [ %w[RDN LD] ], client.provider_list.pluck(:credentials)
    end
    assert_equal isolated, Rails.cache.read(Client::ProviderList.cache_key(unrelated.id))
    assert_equal "cache-provider", @provider.user.reload.name
    @provider.update!(credentials: [])
    [ @client, @other ].each { |client| assert_equal [ [] ], client.provider_list.pluck(:credentials) }
  ensure
    Rails.cache.delete(Client::ProviderList.cache_key(unrelated.id)) if unrelated
  end

  test "credential payload uses one scalar query on cold reads zero on hits and ignores legacy payloads" do
    @provider.update!(credentials: %w[LD RDN])
    @client.enrollments.create!(provider: @extra)
    legacy_key = "clients/#{@client.id}/provider-list/v1"
    Rails.cache.write(legacy_key, [ { name: "Stale legacy label", credentials: "malformed" } ])
    queries = []
    sql = ->(event) do
      queries << event.payload[:sql] if event.payload[:sql].match?(/SELECT.*FROM "(?:enrollments|providers|users)"/m)
    end
    ActiveRecord::Base.uncached do
      ActiveSupport::Notifications.subscribed(sql, "sql.active_record") do
        rows = @client.provider_list
        assert_equal [ @extra.id, @provider.id ], rows.pluck(:provider_id)
        assert_equal [ [], %w[RDN LD] ], rows.pluck(:credentials)
        assert_equal 1, queries.size, "Projection must not load each provider/user separately"
        assert_equal rows, @client.provider_list
        assert_equal 1, queries.size, "Redis hit must issue no list SQL"
      end
    end
  ensure
    Rails.cache.delete(legacy_key) if legacy_key
  end

  test "multiple enrollment saves in one commit invalidate both previous and current clients" do
    @client.provider_list
    @other.provider_list
    Enrollment.transaction do
      @enrollment.update!(client: @other)
      @enrollment.update!(plan: :premium)
    end
    [ @client, @other ].each { |client| assert_nil Rails.cache.read(Client::ProviderList.cache_key(client.id)) }
    assert_empty @client.provider_list
    assert_equal [ "premium" ], @other.provider_list.pluck(:plan)
  end

  test "warm display cache cannot grant removed provider journal or feed access" do
    entry = @client.journal_entries.create!(text: "Private cache regression")
    actor = @provider.user
    assert JournalEntryPolicy.new(actor, entry).show?
    stale = @client.provider_list
    @enrollment.destroy!
    assert_empty @client.provider_list
    # Even deliberately stale display data must never become permission evidence.
    Rails.cache.write(Client::ProviderList.cache_key(@client.id), stale)
    assert_not JournalEntryPolicy.new(actor, entry).show?
    assert_not ClientPolicy.new(actor, @client).show?
    assert_empty JournalEntryPolicy::Scope.new(actor, JournalEntry.all).resolve
    assert_empty actor.provider.journal_entries
    assert_equal "cache-provider@example.test", actor.email
    assert actor.valid_password?(DomainAccounts::PASSWORD)
    log_in_as(actor)
    assert_redirected_to root_path
    [ "/journal_entries/#{entry.id}", "/clients/#{@client.id}/journal_entries" ].each do |path|
      get path
      assert_equal 404, response.status
      assert_not_includes response.body, entry.text
    end
    get "/journal_entries"
    assert_equal 200, response.status
    assert_not_includes response.body, entry.text
    assert JournalEntry.exists?(entry.id)
  end

  test "test cache clearing preserves development keys and refills from its own scenario" do
    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://127.0.0.1:56379/0"))
    sentinel = "healthie:development:qa-isolation-#{SecureRandom.hex(8)}"
    redis.set(sentinel, "preserve", ex: 60)
    expected = [ { enrollment_id: @enrollment.id, provider_id: @provider.id, name: "cache-provider", plan: "basic", credentials: [] } ]
    assert_equal expected, @client.provider_list
    Rails.cache.clear
    assert_nil Rails.cache.read(Client::ProviderList.cache_key(@client.id))
    assert_equal expected, @client.provider_list
    assert_equal "preserve", redis.get(sentinel)
    assert_equal "healthie_test", ActiveRecord::Base.connection.current_database
  ensure
    redis&.del(sentinel) if sentinel
  end

  private

  def account(name, role)
    create_test_account(role, name).tap { |user| @users << user }
  end
end
