abort "Seeds are only for local development/test" unless Rails.env.development? || Rails.env.test?

require_relative "demo/roster"
require_relative "demo/journals"

# Manual demo only. Fixed inclusive 90-day window: July 23–October 20, 2026 UTC.
# No schema flags or text matching: a journal slot is (client, timestamp, ordinal).
# Existing slots keep their text/IDs; see README for restoration/collision semantics.
reference = Time.iso8601("2026-10-20T08:00:00Z")
started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

User.transaction do
  accounts = {}
  [ [ "provider", DemoSeeds::PROVIDERS ], [ "client", DemoSeeds::CLIENTS ] ].each do |role, roster|
    roster.each_with_index do |(login, name, credentials), index|
      email = "#{login}@healthie.example"
      user = User.find_by(email: email)
      if user
        raise "Seed role mismatch for #{email}" unless user.role == role
      else
        user = User.create_account!(name: name, email: email, password: "Healthie-demo-2026", role: role)
        # Profile ages intentionally disagree with enrollment ages below.
        timestamp = reference - (180 + index).days
        user.update!(created_at: timestamp, updated_at: timestamp)
        user.public_send(role).update!(created_at: timestamp, updated_at: timestamp)
      end
      profile = user.public_send(role)
      # Preserve edited nonempty credentials; fill blanks, including legacy Casey.
      profile.update!(credentials: credentials) if role == "provider" && profile.credentials.empty?
      accounts[login] = profile
    end
  end

  # Stable pair order also defines IDs for exact enrollment timestamp ties.
  pairs = [ [ 0, 0, "basic" ], [ 1, 0, "premium" ], [ 0, 1, "premium" ] ]
  (3..39).reject { |client| client == 10 }.each { |client| pairs << [ 0, client, client.even? ? "basic" : "premium" ] }
  (3..8).each { |provider| pairs << [ provider, 0, provider.even? ? "basic" : "premium" ] }
  [ 3, 4, 8 ].each { |client| pairs << [ 1, client, "basic" ] }
  pairs << [ 27, 11, "basic" ] # Cedar: exactly one client.
  pairs.concat([ [ 26, 12, "premium" ], [ 26, 13, "basic" ] ]) # Pearl: two.
  # Give all eligible clients a first relationship. Jamie, Luna and the final
  # five invented clients remain unassigned. Clients 90–94 remain single-provider.
  (3..94).reject { |client| client == 10 }.each do |client|
    next if pairs.any? { |_, existing, _| existing == client }
    pairs << [ 3 + client % 23, client, client.even? ? "basic" : "premium" ]
  end
  # Shared clients get several providers, rather than independent random rows.
  (3..89).reject { |client| client == 10 }.cycle(30) do |client|
    break if pairs.size == 200
    provider = 1 + (client * 7 + pairs.size) % 25
    provider = 3 if provider == 2
    next if pairs.any? { |p, c, _| p == provider && c == client }
    pairs << [ provider, client, (provider + client).even? ? "basic" : "premium" ]
  end
  raise "Demo enrollment target not reached" unless pairs.size == 200
  pairs.each_with_index do |(provider_index, client_index, plan), index|
    provider = accounts.fetch(DemoSeeds::PROVIDERS[provider_index][0])
    client = accounts.fetch(DemoSeeds::CLIENTS[client_index][0])
    timestamp = case index
    when 0, 2 then Time.iso8601("2026-10-18T09:00:00Z")
    when 1 then Time.iso8601("2026-10-19T09:00:00Z")
    when 3, 4 then reference + 2.hours # Morgan's latest two clients tie.
    when 39, 40 then reference + 3.hours # Alex's latest two providers tie.
    else reference - (index * 13 % 120).days
    end
    Enrollment.find_or_create_by!(provider: provider, client: client) do |enrollment|
      enrollment.plan = plan
      enrollment.created_at = enrollment.updated_at = timestamp
    end
  end

  # 50 + 12 + 0 + 45 + 40 + 35 + 30 + 25 + 40 + 0 + 15 + 2,
  # then 87 clients with 8 entries and the last with 10 = 1,000.
  volumes = [ 50, 12, 0, 45, 40, 35, 30, 25, 40, 0, 15, 2 ] + [ 8 ] * 87 + [ 10 ]
  DemoSeeds::CLIENTS.each_with_index do |(login, _), client_index|
    client = accounts.fetch(login)
    slots = case login
    when "client"
      [ [ Time.iso8601("2026-10-17T09:00:00Z"), "Walked after breakfast and felt energized." ],
        [ Time.iso8601("2026-10-19T18:00:00Z"), "Prepared lunch for tomorrow." ],
        [ Time.iso8601("2026-10-19T18:00:00Z"), "An evening stretch helped me unwind." ] ]
    when "unrelated-client"
      [ [ reference, "Tried a new breakfast recipe." ] ]
    else []
    end
    (volumes.fetch(client_index) - slots.size).times do |index|
      # First and third generated entries tie; many clients also tie with each
      # other. Other dates/cadence leave quiet periods and several busy days.
      day = case index
      when 0, 2 then 0
      when 1 then 89
      else (index * 7 + client_index * 11) % 88 + 1
      end
      timestamp = reference - day.days + (index > 2 ? index % 10 : 0).hours
      slots << [ timestamp, DemoSeeds.journal_text(login, index, client_index) ]
    end
    slots.group_by(&:first).each do |timestamp, entries|
      # Existing rows at that exact timestamp occupy slots even if text was
      # edited. Never overwrite journals or identify them by mutable text.
      existing = client.journal_entries.where(created_at: timestamp).count
      entries.drop(existing).each do |_, text|
        client.journal_entries.create!(text: text, created_at: timestamp, updated_at: timestamp)
      end
    end
  end
end

# Only after successful commit. RedisCacheStore#clear respects current namespace.
Rails.cache.clear
elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
puts "Fictional manual demo baseline: 30 providers, 100 clients, 200 enrollments, 1,000 journal entries."
puts "Current database totals (including manual data): #{Provider.count} providers, #{Client.count} clients, #{Enrollment.count} enrollments, #{JournalEntry.count} journals."
puts "Seed completed in #{elapsed.round(2)}s; cleared only healthie:#{Rails.env} cache."
