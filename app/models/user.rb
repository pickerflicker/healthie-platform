class User < ApplicationRecord
  devise :database_authenticatable, :validatable

  enum :role, { provider: "provider", client: "client" }, validate: true
  has_one :provider, inverse_of: :user, dependent: :destroy, autosave: true
  has_one :client, inverse_of: :user, dependent: :destroy, autosave: true
  validates :name, presence: true
  validate :matching_profile
  validate :immutable_role, on: :update

  # Saving the parent and its validated profile is one ActiveRecord transaction.
  def self.create_account!(name:, email:, password:, role:)
    user = new(name: name, email: email, password: password, role: role)
    user.build_provider if user.provider?
    user.build_client if user.client?
    user.save!
    user
  end

  private

  def matching_profile
    expected, other = provider? ? [ provider, client ] : [ client, provider ]
    errors.add(:base, "Account requires exactly its matching role profile") if expected.nil? || expected.marked_for_destruction? || other.present?
  end

  def immutable_role
    errors.add(:role, "cannot be changed") if will_save_change_to_role?
  end
end
