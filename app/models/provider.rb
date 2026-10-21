class Provider < ApplicationRecord
  CREDENTIAL_GROUPS = {
    "Medicine, eye care, dental and chiropractic" => {
      "MD" => "Doctor of Medicine",
      "DO" => "Doctor of Osteopathic Medicine",
      "OD" => "Doctor of Optometry",
      "DDS" => "Doctor of Dental Surgery",
      "DMD" => "Doctor of Dental Medicine",
      "DPM" => "Doctor of Podiatric Medicine",
      "DC" => "Doctor of Chiropractic"
    }.freeze,
    "Nursing and physician assistants" => {
      "RN" => "Registered Nurse",
      "LPN" => "Licensed Practical Nurse",
      "LVN" => "Licensed Vocational Nurse",
      "APRN" => "Advanced Practice Registered Nurse",
      "NP" => "Nurse Practitioner",
      "DNP" => "Doctor of Nursing Practice",
      "BSN" => "Bachelor of Science in Nursing",
      "MSN" => "Master of Science in Nursing",
      "CNM" => "Certified Nurse-Midwife",
      "CRNA" => "Certified Registered Nurse Anesthetist",
      "PA-C" => "Physician Assistant-Certified"
    }.freeze,
    "Nutrition and diabetes care" => {
      "RD" => "Registered Dietitian",
      "RDN" => "Registered Dietitian Nutritionist",
      "LD" => "Licensed Dietitian",
      "LDN" => "Licensed Dietitian/Nutritionist",
      "CNS" => "Certified Nutrition Specialist",
      "CDCES" => "Certified Diabetes Care and Education Specialist"
    }.freeze,
    "Mental health and academic degrees" => {
      "PhD" => "Doctor of Philosophy",
      "PsyD" => "Doctor of Psychology",
      "LCSW" => "Licensed Clinical Social Worker",
      "LMFT" => "Licensed Marriage and Family Therapist",
      "LPC" => "Licensed Professional Counselor",
      "LMHC" => "Licensed Mental Health Counselor",
      "LPCC" => "Licensed Professional Clinical Counselor",
      "MSW" => "Master of Social Work",
      "LSW" => "Licensed Social Worker",
      "LICSW" => "Licensed Independent Clinical Social Worker",
      "NCC" => "National Certified Counselor",
      "BCBA" => "Board Certified Behavior Analyst"
    }.freeze,
    "Physical and occupational therapy" => {
      "PT" => "Physical Therapist",
      "DPT" => "Doctor of Physical Therapy",
      "OTD" => "Doctor of Occupational Therapy",
      "OTR" => "Occupational Therapist Registered",
      "PTA" => "Physical Therapist Assistant",
      "COTA" => "Certified Occupational Therapy Assistant"
    }.freeze,
    "Pharmacy" => {
      "PharmD" => "Doctor of Pharmacy",
      "RPh" => "Registered Pharmacist"
    }.freeze,
    "Audiology and speech-language pathology" => {
      "AuD" => "Doctor of Audiology",
      "CCC-A" => "Certificate of Clinical Competence in Audiology",
      "CCC-SLP" => "Certificate of Clinical Competence in Speech-Language Pathology"
    }.freeze,
    "Naturopathic medicine and acupuncture" => {
      "ND" => "Doctor of Naturopathic Medicine",
      "LAc" => "Licensed Acupuncturist"
    }.freeze,
    "Health and wellness coaching" => {
      "NBC-HWC" => "National Board Certified Health & Wellness Coach"
    }.freeze
  }.freeze
  CREDENTIALS = CREDENTIAL_GROUPS.values.reduce({}, :merge).freeze

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
    # The empty string is Rails' hidden checkbox sentinel, not a credential.
    normalized = values.reject(&:empty?).uniq
      .sort_by { |value| CREDENTIALS.keys.index(value) || CREDENTIALS.size }
    super(normalized)
  end

  private

  def supported_credentials
    if credentials.nil? || (credentials - CREDENTIALS.keys).any?
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
