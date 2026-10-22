class JournalEntry < ApplicationRecord
  MONTHLY_ENTRIES_LIMIT = 10

  belongs_to :client, inverse_of: :journal_entries
  # NULL is reserved for pre-attribution legacy history, never new entries.
  belongs_to :provider, optional: true, inverse_of: :journal_entries
  validates :text, presence: true
  validates :provider, presence: true, if: :new_record?
  before_validation :prepare_creation, if: :new_record?
  validate :eligible_enrollment_and_monthly_limit, if: :new_record?
  validate :immutable_ownership_and_timestamp, if: :persisted?

  private

  def prepare_creation
    # save/save! wrap validation AND insertion in one transaction. The client
    # survives enrollment removal/re-addition. valid? alone reserves no slot.
    Client.lock.find_by(id: client_id) if client_id
    @creation_time = Time.current
    # Keep the server timestamp in the same month as validation, even if the
    # insert crosses midnight. A prior valid? must not freeze that timestamp.
    if created_at.nil? || created_at == @server_created_at
      self.created_at = @creation_time
      @server_created_at = created_at
    end
  end

  def eligible_enrollment_and_monthly_limit
    enrollment = if client_id && provider_id
      Enrollment.uncached { Enrollment.find_by(client_id: client_id, provider_id: provider_id) }
    end
    unless enrollment && Enrollment.plans.key?(enrollment.plan)
      errors.add(:provider, "must have a current enrollment with a valid plan")
      return
    end
    return if enrollment.premium?

    month_start = @creation_time.beginning_of_month
    count = JournalEntry.uncached do
      JournalEntry.where(client_id: client_id, provider_id: provider_id,
        created_at: month_start...month_start.next_month).count
    end
    errors.add(:base, "Basic plan allows at most #{MONTHLY_ENTRIES_LIMIT} journal entries per provider each month") if count >= MONTHLY_ENTRIES_LIMIT
  end

  def immutable_ownership_and_timestamp
    %i[client_id provider_id created_at].each do |attribute|
      errors.add(attribute, "cannot be changed") if will_save_change_to_attribute?(attribute)
    end
  end
end
