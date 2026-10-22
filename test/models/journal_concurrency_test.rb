require "test_helper"
require "timeout"
require_relative "../support/domain_accounts"

class JournalConcurrencyTest < ActiveSupport::TestCase
  include DomainAccounts
  self.use_transactional_tests = false

  test "separate simultaneous connections at nine persist exactly one tenth entry" do
    config = ActiveRecord::Base.connection_db_config
    assert Rails.env.test? && config.database == "healthie_test"
    client = create_test_account("client", "Concurrent Client").client
    provider = create_test_account("provider", "Concurrent Provider").provider
    client.enrollments.create!(provider: provider, plan: :basic)
    9.times { client.journal_entries.create!(provider: provider, text: "Existing") }
    ready = Queue.new
    threads = []
    client.with_lock do
      threads = 2.times.map do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do |connection|
            ready << connection.select_value("SELECT pg_backend_pid()")
            entry = JournalEntry.create(client_id: client.id, provider_id: provider.id, text: "Concurrent")
            [ entry.persisted?, entry.errors.full_messages ]
          end
        end
      end
      pids = 2.times.map { Timeout.timeout(10) { ready.pop } }
      assert_equal 2, pids.uniq.size
      # Both saves must actually be waiting on the same stable client lock,
      # rather than two sequential calls that happen to pass.
      Timeout.timeout(10) do
        loop do
          waiting = ActiveRecord::Base.connection.select_value("SELECT count(*) FROM pg_stat_activity WHERE pid IN (#{pids.join(',')}) AND wait_event_type = 'Lock'")
          break if waiting == 2
          sleep 0.01
        end
      end
    end
    results = threads.map { |thread| Timeout.timeout(10) { thread.value } }
    assert_equal [ false, true ], results.map(&:first).sort_by { |persisted| persisted ? 1 : 0 }
    assert_match "Basic plan allows at most 10", results.find { |persisted, _| !persisted }.last.join
    assert_equal 10, JournalEntry.where(client: client, provider: provider).count

    # A valid? result/count cached before another connection commits cannot
    # bypass the cap when the same object is later saved in the same request.
    client.journal_entries.order(:id).last.destroy!
    JournalEntry.cache do
      stale = JournalEntry.new(client: client, provider: provider, text: "Stale validation")
      assert stale.valid?
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          JournalEntry.create!(client: client, provider: provider, text: "Another connection")
        end
      end.value
      assert_not stale.save
    end
    assert_equal 10, JournalEntry.where(client: client, provider: provider).count
  ensure
    threads&.each { |thread| thread.join(10) }
    if client
      client.journal_entries.delete_all
      client.user.destroy!
    end
    provider&.user&.destroy!
  end
end
