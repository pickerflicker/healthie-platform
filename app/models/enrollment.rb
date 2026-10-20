class Enrollment < ApplicationRecord
  belongs_to :provider
  belongs_to :client

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  enum :plan, { basic: "basic", premium: "premium" }, validate: true
  validates :provider_id, uniqueness: { scope: :client_id, message: "is already enrolled" }

  after_save :invalidate_provider_lists
  after_destroy :invalidate_provider_lists

  private

  def invalidate_provider_lists
    # Capture every affected owner, including earlier saves in this transaction.
    client_ids = [ client_id, *saved_change_to_client_id ].compact.uniq
    ActiveRecord.after_all_transactions_commit do
      client_ids.each { |id| Rails.cache.delete(Client.provider_list_cache_key(id)) }
    end
  end
end
