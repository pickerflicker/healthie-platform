require "test_helper"
require "redis"
require "securerandom"

class RuntimeCacheTest < ActiveSupport::TestCase
  test "test cache writes reach isolated Redis namespace" do
    key = "qa-runtime-#{SecureRandom.hex(8)}"
    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://127.0.0.1:56379/0"))

    assert Rails.cache.write(key, "test-only")
    assert_equal "test-only", Rails.cache.read(key)
    assert redis.exists?("healthie:test:#{key}"), "test cache must reach the test Redis namespace"
    assert_not redis.exists?("healthie:development:#{key}")
    assert_equal "healthie_test", ActiveRecord::Base.connection.current_database
  ensure
    Rails.cache.delete(key) if key
  end
end
