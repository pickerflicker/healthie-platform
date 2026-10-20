abort "Seeds are only for local development/test" unless Rails.env.development? || Rails.env.test?

User.transaction do
  [ [ "provider", "Morgan Patel", "provider" ], [ "provider", "Taylor Reed", "second-provider" ],
    [ "provider", "Casey Park", "empty-provider" ], [ "client", "Alex Rivera", "client" ],
    [ "client", "Sam Chen", "unrelated-client" ], [ "client", "Jamie Brooks", "empty-client" ] ].each do |role, name, login|
    email = "#{login}@healthie.example"
    user = User.find_by(email: email)
    if user
      raise "Seed role mismatch for #{email}" unless user.role == role
      user.update!(name: name, password: "Healthie-demo-2026")
    else
      User.create_account!(name: name, email: email, password: "Healthie-demo-2026", role: role)
    end
  end
end

Enrollment.transaction do
  # Account/profile ages deliberately disagree with enrollment age. The provider-facing
  # relationships tie on time so their enrollment IDs decide the displayed order.
  [ [ "provider", "client", "basic", "2026-10-18T09:00:00Z" ],
    [ "second-provider", "client", "premium", "2026-10-19T09:00:00Z" ],
    [ "provider", "unrelated-client", "premium", "2026-10-18T09:00:00Z" ] ].each do |provider_login, client_login, plan, timestamp|
    provider = User.find_by!(email: "#{provider_login}@healthie.example").provider
    client = User.find_by!(email: "#{client_login}@healthie.example").client
    Enrollment.find_or_create_by!(provider: provider, client: client) do |enrollment|
      enrollment.plan = plan
      enrollment.created_at = Time.iso8601(timestamp)
    end
  end
end

# Fixed creation times make the browsing baseline and tie-breaking repeatable.
JournalEntry.transaction do
  [ [ "client", "2026-10-17T09:00:00Z", "Walked after breakfast and felt energized." ],
    [ "client", "2026-10-19T18:00:00Z", "Prepared lunch for tomorrow." ],
    [ "client", "2026-10-19T18:00:00Z", "An evening stretch helped me unwind." ],
    [ "unrelated-client", "2026-10-20T08:00:00Z", "Tried a new breakfast recipe." ] ].each do |login, timestamp, text|
    client = User.find_by!(email: "#{login}@healthie.example").client
    client.journal_entries.find_or_create_by!(created_at: Time.iso8601(timestamp), text: text)
  end
end

# Seeds may restore relationships or identity data; never retain an earlier list.
# RedisCacheStore#clear is restricted to this project's current-env namespace.
Rails.cache.clear
