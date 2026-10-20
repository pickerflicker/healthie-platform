class Client::ProviderList
  def self.cache_key(client_id)
    "clients/#{client_id}/provider-list/v1"
  end

  def self.invalidate_after_commit(&affected_client_ids)
    ActiveRecord.after_all_transactions_commit do
      affected_client_ids.call.compact.uniq.each do |client_id|
        Rails.cache.delete(cache_key(client_id))
      end
    end
  end

  def initialize(client)
    @client = client
  end

  def fetch
    Rails.cache.fetch(self.class.cache_key(@client.id), expires_in: 1.minute) { query }
  end

  private

  def query
    @client.enrollments.joins(provider: :user).order(created_at: :desc, id: :desc)
      .pluck(:id, :provider_id, "users.name", :plan).map do |enrollment_id, provider_id, name, plan|
        { enrollment_id: enrollment_id, provider_id: provider_id, name: name, plan: plan }
      end
  end
end
