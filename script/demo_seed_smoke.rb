# Explicit, opt-in seed validation; never required by test_helper/check/acceptance.
# Run only after bin/reset-test-data healthie_test. Leaves validation data in test.
require "redis"
config = ActiveRecord::Base.connection_db_config
abort "Requires disposable local healthie_test" unless Rails.env.test? && config.database == "healthie_test" && %w[127.0.0.1 localhost].include?(config.configuration_hash[:host])
abort "Requires empty test database; run bin/reset-test-data healthie_test" unless User.count.zero?

def verify(condition, message)
  raise message unless condition
end

def snapshot
  [ User, Provider, Client, Enrollment, JournalEntry ].map { |model| model.order(:id).map(&:attributes) }
end

def account(login)
  User.find_by!(email: "#{login}@healthie.example")
end

load Rails.root.join("db/seeds.rb")
verify([ Provider.count, Client.count, Enrollment.count, JournalEntry.count ] == [ 30, 100, 200, 1000 ], "Wrong clean volumes")
morgan = account("provider").provider
alex = account("client").client
taylor = account("second-provider").provider
sam = account("unrelated-client").client
verify([ morgan.clients.count, alex.providers.count, alex.journal_entries.count ] == [ 38, 8, 50 ], "Wrong primary volumes")
verify(Provider.all.all? { |p| p.credentials.present? && (p.credentials - Provider::CREDENTIALS.keys).empty? }, "Missing/invalid credentials")
verify(account("empty-provider").provider.clients.empty?, "Casey not empty")
verify(account("empty-client").client.providers.empty? && account("empty-client").client.journal_entries.empty?, "Jamie not empty")
verify(account("quinn-stillwater").client.journal_entries.empty? && morgan.clients.exists?(account("quinn-stillwater").client.id), "Missing enrolled zero-journal")
verify(account("luna-lovegood").client.providers.empty? && account("luna-lovegood").client.journal_entries.count == 15, "Missing unassigned history")
verify(account("pip-willow").client.journal_entries.count == 2, "Missing quiet client")
verify(morgan.clients.exists?(sam.id) && !taylor.clients.exists?(sam.id), "Sam denial actor invalid")
verify(!morgan.clients.exists?(account("luna-lovegood").client.id), "Morgan unrelated scenario invalid")
verify(alex.enrollments.find_by!(provider: morgan).basic? && alex.enrollments.find_by!(provider: taylor).premium?, "Legacy plans lost")
verify(account("sherlock-holmes").client.providers.exists?(morgan.id) && account("sherlock-holmes").client.providers.exists?(taylor.id), "Shared scenario missing")
verify(JournalEntry.minimum(:created_at) == Time.iso8601("2026-07-23T08:00:00Z") && JournalEntry.maximum(:created_at) == Time.iso8601("2026-10-20T08:00:00Z"), "Wrong 90-day endpoints")
verify(account("provider").valid_password?("Healthie-demo-2026") && account("client").valid_password?("Healthie-demo-2026"), "Primary password invalid")

orders = -> { [ morgan.enrollments.order(created_at: :desc, id: :desc).pluck(:id), alex.enrollments.order(created_at: :desc, id: :desc).pluck(:id), alex.journal_entries.order(created_at: :desc, id: :desc).pluck(:id), morgan.journal_entries.order(created_at: :desc, id: :desc).pluck(:id) ] }
before = snapshot
before_order = orders.call
load Rails.root.join("db/seeds.rb")
verify(snapshot == before && orders.call == before_order, "Unchanged reseed changed records or order")
puts "PASS unchanged rerun: all attributes, IDs, timestamps, password digests and four query orders identical"
puts "Plans: #{Enrollment.group(:plan).count.inspect}"
puts "Credentials: #{Provider.group(:credentials).count.inspect}"
puts "Morgan: #{morgan.clients.count} clients / #{morgan.journal_entries.count} feed entries; Alex: 8 providers / 50 journals"
puts "Provider volumes: #{Provider.order(:id).map { |p| [ p.name, p.clients.count ] }.inspect}"
puts "Client relationship distribution: #{Client.all.group_by { |c| c.providers.count }.transform_values(&:size).sort.to_h.inspect}"
puts "90-day range: #{JournalEntry.minimum(:created_at).iso8601} .. #{JournalEntry.maximum(:created_at).iso8601}"

# Real manually-created data and deliberate edits, followed by missing-state repair.
manual_provider = User.create_account!(name: "Manual Sentinel", email: "sentinel-provider@example.test", password: "Sentinel-only-2026", role: "provider").provider
manual_client = User.create_account!(name: "Manual Client", email: "sentinel-client@example.test", password: "Sentinel-only-2026", role: "client").client
manual_client.enrollments.create!(provider: manual_provider, plan: :premium)
manual_client.journal_entries.create!(text: "Manually entered sentinel")
alex.enrollments.create!(provider: manual_provider, plan: :basic)
account("provider").update!(name: "Manually edited Morgan", password: "Edited-password-2026")
morgan.update!(credentials: %w[CNS])
alex.journal_entries.order(:id).first.update!(text: "Edited baseline story survives")
alex.enrollments.find_by!(provider: morgan).update!(plan: :premium)
manual_before = snapshot
redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://127.0.0.1:56379/0"))
foreign_keys = [ "unrelated:pic286:#{Process.pid}", "healthie:development:pic286-smoke-#{Process.pid}" ]
begin
  foreign_keys.each { |key| redis.set(key, "keep", ex: 300) }
  alex.provider_list
  verify(Rails.cache.exist?(Client::ProviderList.cache_key(alex.id)), "Cache not warmed")
  load Rails.root.join("db/seeds.rb")
  verify(snapshot == manual_before, "Manual records or edits changed")
  verify(!Rails.cache.exist?(Client::ProviderList.cache_key(alex.id)), "Current environment cache not cleared")
  verify(foreign_keys.all? { |key| redis.get(key) == "keep" }, "Other namespace cleared")
  puts "PASS sentinel accounts, enrollments, journals, edited name/password/credentials/text/plan; cache invalidation and unrelated/development key preservation"
ensure
  redis.del(*foreign_keys)
end
# Explicitly demonstrate the documented exception: missing baseline relationships
# and blank provider credentials are restored, not manual deletions retained.
alex.enrollments.find_by!(provider: morgan).destroy!
morgan.update!(credentials: [])
load Rails.root.join("db/seeds.rb")
verify(alex.enrollments.find_by!(provider: morgan).basic? && morgan.reload.credentials == %w[RDN LD], "Missing baseline state not restored")
puts "PASS missing baseline relationship and blank credentials restored; manual edits otherwise retained"
