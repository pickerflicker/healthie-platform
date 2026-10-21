class Provider < ApplicationRecord
  CREDENTIALS = {
    "MD" => "Doctor of Medicine",
    "RD" => "Registered Dietitian",
    "RDN" => "Registered Dietitian Nutritionist",
    "LD" => "Licensed Dietitian",
    "CNS" => "Certified Nutrition Specialist",
    "CDCES" => "Certified Diabetes Care and Education Specialist"
  }.freeze

  has_many :enrollments, dependent: :destroy
  has_many :clients, through: :enrollments
  has_many :journal_entries, through: :clients
  belongs_to :user, inverse_of: :provider
  delegate :name, :email, to: :user
  validates :user_id, uniqueness: true
  validate :matching_role
  validate :immutable_account, on: :update
  validate :supported_credentials
  before_destroy :retain_account_profile
  after_update :invalidate_provider_lists, if: :saved_change_to_credentials?

  def credentials=(values)
    @malformed_credentials = !values.is_a?(Array) || values.any? { |value| !value.is_a?(String) }
    # The empty string is Rails' hidden checkbox sentinel, not a credential.
    normalized = @malformed_credentials ? [] : values.reject(&:empty?).uniq
      .sort_by { |value| CREDENTIALS.keys.index(value) || CREDENTIALS.size }
    super(normalized)
  end

  private

  def supported_credentials
    if @malformed_credentials
      errors.add(:credentials, "must be a list of supported selections")
    elsif credentials.nil? || (credentials - CREDENTIALS.keys).any?
      errors.add(:credentials, "must contain only supported selections")
    end
  end

  def invalidate_provider_lists
    Client::ProviderList.invalidate_after_commit { enrollments.distinct.pluck(:client_id) }
  end

  def matching_role
    errors.add(:user, "must be a provider without a client profile") unless user&.provider? && user.client.nil?
  end

  def immutable_account
    errors.add(:user, "cannot be reassigned") if will_save_change_to_user_id?
  end

  def retain_account_profile
    throw :abort unless destroyed_by_association
  end
end
