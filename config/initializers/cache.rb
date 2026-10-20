if Rails.env.development? || Rails.env.test?
  Rails.application.config.cache_store = :redis_cache_store, {
    url: ENV.fetch("REDIS_URL", "redis://127.0.0.1:56379/0"),
    namespace: "healthie:#{Rails.env}",
    expires_in: 1.hour
  }
end
