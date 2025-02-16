# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                    :integer          not null, primary key
#  account_type          :string           default("unknown")
#  active                :boolean          default(FALSE)
#  classcode             :string(255)
#  email                 :string(255)
#  flags                 :string           default([]), not null, is an Array
#  flagset               :string           default("production"), not null
#  ip_address            :inet
#  last_active           :datetime
#  last_sign_in          :datetime
#  name                  :string(255)
#  password_digest       :string(255)
#  role                  :string(255)      default("user")
#  send_newsletter       :boolean          default(FALSE)
#  signed_up_with_google :boolean          default(FALSE)
#  time_zone             :string
#  title                 :string
#  token                 :string(255)
#  username              :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  clever_id             :string(255)
#  google_id             :string
#  stripe_customer_id    :string
#
# Indexes
#
#  email_idx                          (email) USING gin
#  index_users_on_active              (active)
#  index_users_on_classcode           (classcode)
#  index_users_on_clever_id           (clever_id)
#  index_users_on_email               (email)
#  index_users_on_google_id           (google_id)
#  index_users_on_role                (role)
#  index_users_on_stripe_customer_id  (stripe_customer_id)
#  index_users_on_time_zone           (time_zone)
#  index_users_on_token               (token)
#  index_users_on_username            (username)
#  name_idx                           (name) USING gin
#  unique_index_users_on_clever_id    (clever_id) UNIQUE WHERE ((clever_id IS NOT NULL) AND ((clever_id)::text <> ''::text) AND ((id > 5593155) OR ((role)::text = 'student'::text)))
#  unique_index_users_on_email        (email) UNIQUE WHERE ((id > 1641954) AND (email IS NOT NULL) AND ((email)::text <> ''::text))
#  unique_index_users_on_google_id    (google_id) UNIQUE WHERE ((id > 1641954) AND (google_id IS NOT NULL) AND ((google_id)::text <> ''::text))
#  unique_index_users_on_username     (username) UNIQUE WHERE ((id > 1641954) AND (username IS NOT NULL) AND ((username)::text <> ''::text))
#  username_idx                       (username) USING gin
#  users_to_tsvector_idx              (to_tsvector('english'::regconfig, (name)::text)) USING gin
#  users_to_tsvector_idx1             (to_tsvector('english'::regconfig, (email)::text)) USING gin
#  users_to_tsvector_idx10            (to_tsvector('english'::regconfig, (username)::text)) USING gin
#  users_to_tsvector_idx11            (to_tsvector('english'::regconfig, split_part((ip_address)::text, '/'::text, 1))) USING gin
#  users_to_tsvector_idx2             (to_tsvector('english'::regconfig, (role)::text)) USING gin
#  users_to_tsvector_idx3             (to_tsvector('english'::regconfig, (classcode)::text)) USING gin
#  users_to_tsvector_idx4             (to_tsvector('english'::regconfig, (username)::text)) USING gin
#  users_to_tsvector_idx5             (to_tsvector('english'::regconfig, split_part((ip_address)::text, '/'::text, 1))) USING gin
#  users_to_tsvector_idx6             (to_tsvector('english'::regconfig, (name)::text)) USING gin
#  users_to_tsvector_idx7             (to_tsvector('english'::regconfig, (email)::text)) USING gin
#  users_to_tsvector_idx8             (to_tsvector('english'::regconfig, (role)::text)) USING gin
#  users_to_tsvector_idx9             (to_tsvector('english'::regconfig, (classcode)::text)) USING gin
#

# rubocop:disable Metrics/ClassLength

class User < ApplicationRecord
  include Student
  include Teacher
  include CheckboxCallback
  include UserCacheable
  include Subscriber
  include UserFlagset

  CHAR_FIELD_MAX_LENGTH = 255
  STAFF_SESSION_DURATION = 12.hours
  USER_INACTIVITY_DURATION = 30.days
  USER_SESSION_DURATION = 30.days

  CLEVER_ID_UNIQUENESS_CONSTRAINT_MINIMUM_ID = 5593155 + 1
  EMAIL_UNIQUENESS_CONSTRAINT_MINIMUM_ID = 1641954 + 1
  GOOGLE_ID_UNIQUENESS_CONSTRAINT_MINIMUM_ID = 1641954 + 1
  USERNAME_UNIQUENESS_CONSTRAINT_MINIMUM_ID = 1641954 + 1

  UNIQUENESS_CONSTRAINT_MINIMUM_ID = [
    CLEVER_ID_UNIQUENESS_CONSTRAINT_MINIMUM_ID,
    EMAIL_UNIQUENESS_CONSTRAINT_MINIMUM_ID,
    GOOGLE_ID_UNIQUENESS_CONSTRAINT_MINIMUM_ID,
    USERNAME_UNIQUENESS_CONSTRAINT_MINIMUM_ID
  ].max

  ADMIN = 'admin'
  TEACHER = 'teacher'
  STUDENT = 'student'
  STAFF = 'staff'
  SALES_CONTACT = 'sales-contact'
  INDIVIDUAL_CONTRIBUTOR = 'individual-contributor'
  ONBOARDING_ROLES   = [STUDENT, TEACHER, INDIVIDUAL_CONTRIBUTOR, ADMIN]
  TEACHER_INFO_ROLES = [TEACHER, INDIVIDUAL_CONTRIBUTOR, ADMIN]
  ROLES              = [TEACHER, STUDENT, STAFF, SALES_CONTACT, ADMIN]
  SAFE_ROLES         = [STUDENT, TEACHER, SALES_CONTACT, ADMIN]

  ALPHA = 'alpha'
  BETA = 'beta'
  GAMMA = 'gamma'
  PRIVATE = 'private'
  ARCHIVED = 'archived'
  COLLEGE_BOARD = 'college_board'
  TESTING_FLAGS = [ALPHA, BETA, GAMMA, PRIVATE, ARCHIVED, COLLEGE_BOARD]
  PERMISSIONS_FLAGS = %w(auditor purchaser school_point_of_contact)
  VALID_FLAGS = TESTING_FLAGS.dup.concat(PERMISSIONS_FLAGS)

  CANVAS_ACCOUNT = 'Canvas'
  CLEVER_ACCOUNT = 'Clever'
  GOOGLE_CLASSROOM_ACCOUNT = 'Google Classroom'

  CANVAS_PROVIDER = 'Canvas'
  CLEVER_PROVIDER = 'Clever'
  GOOGLE_PROVIDER = 'Google'

  SCHOOL_CHANGELOG_ATTRIBUTE = 'school_id'

  LEADING_CAPITALIZE_NAMES = %w(van dit)

  attr_accessor :newsletter,
    :require_password_confirmation_when_password_present,
    :skip_capitalize_names_callback,
    :validate_username

  attribute :role_selected_at_signup, :string

  has_secure_password validations: false
  has_one :admin_info, dependent: :destroy
  has_one :auth_credential, dependent: :destroy
  has_one :teacher_info, dependent: :destroy
  has_many :teacher_info_subject_areas, through: :teacher_info
  has_many :teacher_notifications, dependent: :destroy
  has_many :teacher_notification_settings, dependent: :destroy
  has_many :subject_areas, through: :teacher_info_subject_areas
  has_many :checkboxes
  has_many :credit_transactions
  has_many :invitations, foreign_key: 'inviter_id'
  has_many :objectives, through: :checkboxes
  has_many :user_activity_classifications, dependent: :destroy
  has_many :user_logins, dependent: :destroy
  has_many :user_subscriptions
  has_many :subscriptions, through: :user_subscriptions
  has_many :activity_sessions
  has_many :started_activities, through: :activity_sessions, source: :activity

  has_one :schools_users
  has_one :sales_contact, dependent: :destroy
  has_one :school, through: :schools_users
  has_many :schools_i_coordinate, class_name: 'School', foreign_key: 'coordinator_id'
  has_many :schools_i_authorize, class_name: 'School', foreign_key: 'authorizer_id'

  has_many :schools_admins, class_name: 'SchoolsAdmins'
  has_many :district_admins, dependent: :destroy
  has_many :administered_schools, through: :schools_admins, source: :school, foreign_key: :user_id
  has_many :administered_districts, through: :district_admins, source: :district, foreign_key: :user_id
  has_many :classrooms_teachers
  has_many :teacher_saved_activities, dependent: :destroy, foreign_key: 'teacher_id'
  has_many :activities, through: :teacher_saved_activities
  has_many :classrooms_i_teach, through: :classrooms_teachers, source: :classroom
  has_many :unscoped_classrooms_i_teach, through: :classrooms_teachers, source: :classroom_unscoped
  has_many :students_i_teach, through: :classrooms_i_teach, source: :students

  has_many :units
  has_many :classroom_units, through: :units
  has_many :unit_activities, through: :units
  has_many :classroom_unit_activity_states, through: :unit_activities

  has_many :student_in_classroom, through: :students_classrooms, source: :classroom

  has_many :admin_approval_requests, dependent: :destroy, foreign_key: 'requestee_id'

  has_and_belongs_to_many :districts
  has_one :ip_location
  has_many :user_milestones
  has_many :milestones, through: :user_milestones
  has_many :third_party_user_ids

  has_many :blog_post_user_ratings

  has_many :change_logs
  has_many :stripe_checkout_sessions, dependent: :destroy

  has_many :user_pack_sequence_items, dependent: :destroy

  has_one :user_email_verification, dependent: :destroy

  has_one :learn_worlds_account, dependent: :destroy

  has_many :canvas_accounts, dependent: :destroy
  has_many :canvas_instances, through: :canvas_accounts

  has_many :administered_school_canvas_instance_schools, through: :administered_schools, source: :canvas_instance_schools

  has_many :administered_school_canvas_instances_with_canvas_configs,
    -> { joins(:canvas_config).where.not(canvas_configs: { id: nil }).distinct },
    through: :administered_school_canvas_instance_schools,
    source: :canvas_instance

  has_many :administered_school_canvas_configs, through: :administered_school_canvas_instances_with_canvas_configs, source: :canvas_config

  has_many :admin_report_filter_selections, dependent: :destroy
  has_many :pdf_subscriptions, through: :admin_report_filter_selections

  accepts_nested_attributes_for :auth_credential, :canvas_accounts

  delegate :name, :mail_city, :mail_state,
    to: :school,
    allow_nil: true,
    prefix: :school

  delegate :last_four, to: :stripe_user

  validates :name,
    presence: true,
    format: { without: /\t/, message: 'cannot contain tabs' },
    length: { maximum: CHAR_FIELD_MAX_LENGTH }

  validates :password,
    presence: { if: :requires_password? },
    length: { maximum: CHAR_FIELD_MAX_LENGTH }

  validates :email,
    presence: { if: :email_required? },
    uniqueness: { message: :taken, if: :email_required_or_present? },
    format: { without: /\s/, message: :no_spaces_allowed },
    length: { maximum: CHAR_FIELD_MAX_LENGTH }

  validate :username_cannot_be_an_email

  validates :clever_id, uniqueness: { if: :clever_id_present_and_has_changed? }
  validates :google_id, uniqueness: { if: ->(u) { u.google_id.present? && u.student? } }

  validates_email_format_of :email,
    if: :email_required_or_present?,
    message: :invalid

  validates :username,
    presence: { if: ->(m) { m.email.blank? && m.permanent? } },
    uniqueness: { allow_blank: true, message: :taken },
    format: { without: /\s/, message: :no_spaces_allowed, if: :validate_username? },
    length: { maximum: CHAR_FIELD_MAX_LENGTH }

  validate :validate_flags

  before_validation :generate_student_username_if_absent
  before_validation :prep_authentication_terms
  before_save :capitalize_name, if: proc { will_save_change_to_name? && !skip_capitalize_names_callback }
  before_save :set_time_zone, unless: :time_zone
  before_update :track_google_student_set_password, if: proc { google_student_set_password? }
  after_save :update_invitee_email_address, if: proc { saved_change_to_email? }
  after_save :check_for_school
  after_create :generate_referrer_id, if: proc { teacher? }
  after_create :generate_default_teacher_info, if: :teacher?
  after_create :generate_default_teacher_notification_settings, if: :teacher?

  # This is a little weird, but in our current conception, all Admins are Teachers
  scope :teacher, -> { where(role: [ADMIN, TEACHER]) }
  scope :student, -> { where(role: STUDENT) }
  scope :admin, -> { where(role: ADMIN) }

  scope :teachers_in_schools, lambda { |school_ids|
    distinct
      .joins(:schools_users)
      .left_outer_joins(:classrooms_teachers)
      .joins('LEFT OUTER JOIN classrooms ON classrooms_teachers.classroom_id = classrooms.id')
      .where(schools_users: { school_id: school_ids })
  }

  def self.deleted_users
    where(
      <<-SQL
        name LIKE 'Deleted_User_%'
          AND email LIKE 'deleted_user_%'
          AND username LIKE 'deleted_user_%'
      SQL
    )
  end

  def self.find_by_stripe_customer_id_or_email!(stripe_customer_id, email)
    if stripe_customer_id.present? && User.exists?(stripe_customer_id: stripe_customer_id)
      User.find_by(stripe_customer_id: stripe_customer_id)
    else
      User.find_by!(email: email)
    end
  end

  def self.find_by_canvas_user_external_ids(user_external_ids)
    where(id: CanvasAccount.custom_find_by_user_external_ids(user_external_ids).pluck(:user_id))
  end

  def self.valid_email?(email)
    ValidatesEmailFormatOf.validate_email_format(email).nil?
  end

  def require_email_verification
    create_user_email_verification unless user_email_verification
  end

  def requires_email_verification?
    user_email_verification.present?
  end

  def email_verified?
    user_email_verification.present? && user_email_verification.verified?
  end

  def email_verification_pending?
    requires_email_verification? && !email_verified?
  end

  def verify_email(verification_method, verification_token = nil)
    # Set up email verification records if they don't exist yet
    require_email_verification

    user_email_verification.verify(verification_method, verification_token)
  end

  def email_verification_status
    return UserEmailVerification::PENDING if email_verification_pending?

    return UserEmailVerification::VERIFIED if email_verified?

    return nil
  end

  def email_verification_status=(status)
    case status
    when UserEmailVerification::VERIFIED
      verify_email(UserEmailVerification::STAFF_VERIFICATION)
    when UserEmailVerification::PENDING
      require_email_verification
      user_email_verification.update(verification_method: nil, verified_at: nil)
    end
  end

  def testing_flag
    role == STAFF ? ARCHIVED : flags.find { |f| TESTING_FLAGS.include?(f) }
  end

  def auditor?
    flags.include?('auditor')
  end

  def utc_offset
    if time_zone.present?
      tz = TZInfo::Timezone.get(time_zone)
      tz.period_for_utc(Time.new.utc).utc_total_offset
    else
      0
    end
  end

  def purchaser?
    flags.include?('purchaser')
  end

  def school_poc?
    flags.include?('school_point_of_contact')
  end

  def redeem_credit
    balance = credit_transactions.sum(:amount)

    return if balance <= 0

    new_sub =
      Subscription.create_and_attach_subscriber(
        {
          account_type: 'Premium Credit',
          payment_method: 'Premium Credit',
          expiration: Subscription.redemption_start_date(self) + balance,
          start_date: Subscription.redemption_start_date(self),
          purchaser_id: id
        },
        self
      )

    CreditTransaction.create!(user: self, amount: 0 - balance, source: new_sub) if new_sub
    new_sub
  end

  def subscription_authority_level(subscription_id)
    subscription = Subscription.find subscription_id
    if subscription.purchaser_id == id || subscription.purchaser_email&.downcase == email
      'purchaser'
    elsif subscription.schools.include?(school)
      if school.coordinator == self
        'coordinator'
      elsif school.authorizer == self
        'authorizer'
      end
    end
  end

  def eligible_for_new_subscription?
    subscription.nil? || Subscription::TRIAL_TYPES.include?(subscription.account_type)
  end

  def present_and_future_subscriptions
    subscriptions.active
  end

  def create(*args, **options)
    super
  rescue ActiveRecord::RecordNotUnique => e
    errors.add(:db_level, e)
    false
  end

  def update(*args, **options)
    super
  rescue ActiveRecord::RecordNotUnique => e
    errors.add(:db_level, e)
    false
  end

  def create_or_update(*args, **options)
    super
  rescue ActiveRecord::RecordNotUnique => e
    errors.add(:db_level, e)
    false
  end

  def validate_username?
    validate_username.present? ? validate_username : false
  end

  def username_cannot_be_an_email
    return unless ValidatesEmailFormatOf.validate_email_format(username).nil?

    if new_record?
      errors.add(:username, :invalid)
    else
      db_self = User.find(id)
      errors.add(:username, :invalid) unless db_self.username == username
    end
  end

  def stripe_customer?
    stripe_customer_id.present? && !Stripe::Customer.retrieve(stripe_customer_id).respond_to?(:deleted)
  rescue Stripe::InvalidRequestError
    false
  end

  def safe_role_assignment role
    sanitized_role = SAFE_ROLES.find { |r| r == role.strip }
    self.role = sanitized_role || 'user'
  end

  def self.sorting_name_sql
    <<-SQL
      substring(
        users.name from (
          position(' ' in users.name) + 1
        )
        for (
          char_length(users.name)
        )
      )
      ||
      substring(
        users.name from (
          1
        )
        for (
          position(' ' in users.name)
        )

      ) as sorting_name
    SQL
  end

  def capitalize_name
    temp_name = ::CapitalizeNames.capitalize(name)
    words = temp_name.split
    words[0].capitalize! if words[0].in?(LEADING_CAPITALIZE_NAMES)

    self.name = words.join(' ')
  end

  def admin?
    role.admin?
  end

  def is_admin_for_one_school?
    schools_admins.count == 1
  end

  def is_admin_for_multiple_schools?
    schools_admins.count > 1
  end

  def self.find_by_username_or_email(login_name)
    login_name = login_name.downcase
    User.where('email = ? OR username = ?', login_name, login_name).first
  end

  # replace with authority, cancan or something
  def role
    @role_inquirer ||= ActiveSupport::StringInquirer.new(self[:role])
  end

  def role= role
    remove_instance_variable :@role_inquirer if defined?(@role_inquirer)
    super
  end

  def sorting_name
    "#{last_name}, #{first_name}"
  end

  def student?
    role.student?
  end

  def teacher?
    role.teacher? || admin? # This is a bit weird, but all Admins are Teachers
  end

  def staff?
    role.staff?
  end

  def permanent?
    !role.temporary?
  end

  ## Satismeter settings
  SATISMETER_PERCENT_PER_DAY = ENV['SATISMETER_PERCENT_PER_DAY'] || 10.0
  SATISMETER_ACTIVITIES_PER_STUDENT_THRESHOLD = 3.0
  SATISMETER_NEW_USER_THRESHOLD = 60.days

  def show_satismeter?
    teacher? && satismeter_feature_enabled? && satismeter_threshold_met?
  end

  def satismeter_threshold_met?
    lessons_completed = ActivitySession.for_teacher(id).completed.count(:id)
    student_count = students_i_teach.count('DISTINCT(users.id)')

    (lessons_completed.to_f / student_count) >= SATISMETER_ACTIVITIES_PER_STUDENT_THRESHOLD
  end

  # Enable for all new users and a small percentage of older users.
  def satismeter_feature_enabled?
    created_at >= SATISMETER_NEW_USER_THRESHOLD.ago ||
      Feature.in_day_bucket?(id: id, percent_per_day: SATISMETER_PERCENT_PER_DAY)
  end

  ## End satismeter

  def admins_user_ids
    schools = administered_schools.includes(:users, :admins)
    return if schools.none?

    schools.map { |school| school.users.ids + school.admins.ids }.flatten.uniq
  end

  def refresh_token!
    update(token: SecureRandom.urlsafe_base64)
    save(validate: false)
  end

  def serialized
    "#{role.capitalize}Serializer".constantize.new(self)
  end

  def first_name= first_name
    last_name
    @first_name = first_name
    set_name
  end

  def clear_data
    ClearUserDataWorker.perform_async(id)
  end

  def last_name= last_name
    first_name
    @last_name = last_name
    set_name
  end

  def first_name
    @first_name ||= name.to_s.split[0]
  end

  def last_name
    @last_name ||= name.to_s.split[-1]
  end

  def set_name
    self.name = [@first_name, @last_name].compact.join(' ')
  end

  def generate_password
    # first we need to replace any existing spaces with hyphens
    last_name_with_spaces_replaced_by_hyphens = last_name.split.join('-')
    # then we want to capitalize the first letter
    self.password = self.password_confirmation = last_name_with_spaces_replaced_by_hyphens.slice(0, 1).capitalize + last_name_with_spaces_replaced_by_hyphens.slice(1..-1)
  end

  def generate_student(classroom_id)
    self.role = 'student'
    generate_username(classroom_id)
    generate_password
  end

  def teacher_of_student
    return if classrooms.empty?

    classrooms.first.owner
  end

  def send_account_created_email(temp_password, admin_name)
    UserMailer.account_created_email(self, temp_password, admin_name).deliver_now! if email.present?
  end

  def send_invitation_to_non_existing_user(invitation_email_hash)
    # must be called from inviter account
    UserMailer.invitation_to_non_existing_user(invitation_email_hash).deliver_now! if email.present?
  end

  def send_invitation_to_existing_user(invitation_email_hash)
    UserMailer.invitation_to_existing_user(invitation_email_hash).deliver_now! if email.present?
  end

  def send_join_school_email(school)
    UserMailer.join_school_email(self, school).deliver_now! if email.present?
  end

  def send_lesson_plan_email(lessons, unit)
    UserMailer.lesson_plan_email(self, lessons, unit).deliver_now! if email.present?
  end

  def attach_subscription(subscription)
    user_subscriptions.create(subscription: subscription)
  end

  def send_new_admin_email(school)
    UserMailer.new_admin_email(self, school).deliver_now! if email.present?
  end

  def send_premium_school_missing_email
    UserMailer.premium_missing_school_email(self).deliver_now! if email.present?
  end

  def self.create_from_clever(hash, role_override = nil)
    user = User.where(email: hash[:info][:email]).first_or_initialize
    user = User.new if user.email.nil?
    user.update(
      clever_id: hash[:info][:id],
      token: (hash[:credentials] ? hash[:credentials][:token] : nil),
      role: role_override || hash[:info][:user_type],
      first_name: hash[:info][:name][:first],
      last_name: hash[:info][:name][:last]
    )
    user
  end

  def generate_student_username_if_absent
    return if !student?
    return if username.present?

    classroom_id = classrooms.any? ? classrooms.first.id : nil
    generate_username(classroom_id)
  end

  def newsletter?
    send_newsletter
  end

  def generate_teacher_account_info
    user_attributes = attributes
    user_attributes[:subscription] = subscription ? subscription.attributes : {}
    user_attributes[:subscription]['subscriptionType'] = premium_state
    user_attributes[:minimum_grade_level] = teacher_info&.minimum_grade_level
    user_attributes[:maximum_grade_level] = teacher_info&.maximum_grade_level
    user_attributes[:notification_email_frequency] = teacher_info&.notification_email_frequency
    user_attributes[:show_students_exact_score] = teacher_info&.show_students_exact_score
    user_attributes[:teacher_notification_settings] = teacher_notification_settings_info
    user_attributes[:subject_area_ids] = subject_area_ids

    user_attributes[:school] = school_account_info
    user_attributes[:school_type] = school_type_account_info

    user_attributes
  end

  def delete_dashboard_caches
    delete_classroom_minis_cache
    delete_struggling_students_cache
    delete_difficult_concepts_cache
  end

  def delete_classroom_minis_cache
    $redis.del("user_id:#{id}_classroom_minis")
  end

  def delete_struggling_students_cache
    $redis.del("user_id:#{id}_struggling_students")
  end

  def delete_difficult_concepts_cache
    $redis.del("user_id:#{id}_difficult_concepts")
  end

  def coteacher_invitations
    Invitation.where(archived: false, invitation_type: 'coteacher', invitee_email: email)
  end

  def is_new_teacher_without_school?
    teacher? && !school && previous_changes['id']
  end

  def generate_username(classroom_id = nil)
    self.username = GenerateUsername.run(first_name, last_name, get_class_code(classroom_id))
  end

  def canvas_authorized?
    auth_credential.present? && auth_credential.canvas_authorized?
  end

  def clever_authorized?
    clever_id.present? && auth_credential.present? && auth_credential.clever_authorized?
  end

  def google_authorized?
    google_id.present? && auth_credential.present? && auth_credential.google_authorized?
  end

  def google_access_expired?
    google_id.present? && auth_credential.present? && auth_credential.google_access_expired?
  end

  def google_access_expired_and_no_password?
    google_access_expired? && password_digest.nil?
  end

  # Note this is an incremented count, so could be off.
  def completed_activity_count
    user_activity_classifications.sum(:count)
  end

  def associated_schools
    [school].concat(administered_schools).uniq.select { |s| s.present? && School::ALTERNATIVE_SCHOOL_NAMES.exclude?(s.name) }
  end

  def staff_session_duration_exceeded?
    return false unless staff?
    return false if last_sign_in.nil?

    last_sign_in < STAFF_SESSION_DURATION.ago
  end

  def inactive_too_long?
    last_sign_in_too_long_ago? && last_active_too_long_ago?
  end

  def last_sign_in_too_long_ago?
    return false if last_sign_in.nil?

    last_sign_in < USER_SESSION_DURATION.ago
  end

  def last_active_too_long_ago?
    return true if last_active.nil?

    last_active < USER_INACTIVITY_DURATION.ago
  end

  def segment_user
    SegmentIntegration::User.new(self)
  end

  def stripe_user
    StripeIntegration::User.new(self)
  end

  def mailer_user
    Mailer::User.new(self)
  end

  # With the introduction of the SALES_CONTACT we now have a sort of
  # "prospective user" type of user.  These people haven't signed up
  # through our onboarding flow, but are given a User record so that we
  # can sync their data to Vitally.  We need to treat these users specially
  # during auth flows because they haven't actually signed up.
  def sales_contact?
    role == SALES_CONTACT
  end

  def set_time_zone
    school_timezone = ::Ziptz.instance.time_zone_name(school&.zipcode || school&.mail_zipcode)

    if school_timezone.present?
      self.time_zone = school_timezone
    else
      geocoder_results = Geocoder.search(ip_address.to_s)
      self.time_zone = geocoder_results.first&.data&.dig('location', 'time_zone')
    end
  end

  def duplicate_empty_student_accounts
    User
      .student
      .where(email: email)
      .where.not(id: id)
      .where.missing(:activity_sessions, :students_classrooms)
  end

  def units_with_same_name(name)
    units.where('name ILIKE ?', name)
  end

  def admin_verification_reason
    admin_info&.verification_reason
  end

  def admin_verification_url
    admin_info&.verification_url
  end

  def admin_sub_role
    admin_info&.sub_role
  end

  def admin_approval_status
    admin_info&.approval_status
  end

  def admin_sub_role=(sub_role)
    if admin_info
      admin_info.update(sub_role: sub_role)
    else
      AdminInfo.create(sub_role: sub_role, user_id: id)
    end
  end

  def learn_worlds_access?
    school_premium? || district_premium? || learn_worlds_access_override?
  end

  def learn_worlds_access_override?
    AppSetting.enabled?(name: AppSetting::LEARN_WORLDS_ACCESS_OVERRIDE, user: self)
  end

  def premium_admin?
    admin? && school_or_district_premium?
  end

  def administered_premium_schools
    administered_schools.premium
  end

  def school_premium?
    school&.subscription&.present?
  end

  def district_premium?
    school&.district&.subscription&.present?
  end

  def school_or_district_premium?
    school_premium? || district_premium?
  end

  def should_render_teacher_premium?
    premium_state == 'paid' && Subscription::OFFICIAL_TEACHER_TYPES.include?(subscription&.account_type)
  end

  def receives_notification_type?(type)
    teacher_notification_settings.exists?(notification_type: type)
  end

  def save_user_pack_sequence_items
    classrooms.each { |classroom| SaveUserPackSequenceItemsWorker.perform_async(classroom.id, id) }
  end

  def record_login
    user_logins.create
  end

  def provider
    return GOOGLE_PROVIDER if google_id.present?
    return CLEVER_PROVIDER if clever_id.present?
    return CANVAS_PROVIDER if canvas_accounts.present?
  end

  def user_external_id(canvas_instance: nil)
    return google_id if google_id.present?

    return clever_id if clever_id.present?

    return nil unless canvas_instance.is_a?(CanvasInstance)

    canvas_accounts
      .find_by(canvas_instance: canvas_instance)
      &.user_external_id
  end

  def unlink_clever_and_google_accounts!
    update!(clever_id: nil, google_id: nil, signed_up_with_google: false)
  end

  def unlink_google_account!
    update!(google_id: nil, signed_up_with_google: false)
  end

  def track_google_student_set_password
    Analytics::SegmentAnalytics.new.track_google_student_set_password(self, teacher_of_student)
  end

  def google_student_set_password?
    student? && google_id.present? && password_digest_changed? && password_digest_was.nil?
  end

  private def validate_flags
    invalid_flags = flags - VALID_FLAGS

    return if invalid_flags.none?

    errors.add(:flags, "invalid flag(s) #{invalid_flags}")
  end

  private def prep_authentication_terms
    self.email = email.downcase unless email.blank?
    self.username = username.downcase unless username.blank?
  end

  private def check_for_school
    return unless school

    find_or_create_checkbox('Add School', self)
  end

  private def email_required_or_present?
    email_required? or email.present?
  end

  private def email_required?
    return false if clever_id
    return false if role.temporary?
    return true if teacher?

    false
  end

  private def clever_id_present_and_has_changed?
    return false if !clever_id
    return true if new_record?

    existing_user = User.find_by_id(id)
    existing_user.clever_id != clever_id
  end

  private def requires_password?
    return false if clever_id || google_id || canvas_accounts.present?

    permanent? && new_record?
  end

  private def get_class_code(classroom_id)
    return 'student' if classroom_id.nil?

    Classroom.find(classroom_id).code
  end

  private def update_invitee_email_address
    Invitation.where(invitee_email: email_before_last_save).update_all(invitee_email: email, updated_at: DateTime.current)
  end

  private def generate_default_teacher_info
    # in addition to setting the notification_email_frequency here, show_students_exact_score is also being set to true automatically on creation
    create_teacher_info(notification_email_frequency: TeacherInfo::DAILY_EMAIL, role_selected_at_signup:)
  end

  private def generate_default_teacher_notification_settings
    TeacherNotificationSetting::DEFAULT_FOR_NEW_USERS.each do |notification_type|
      teacher_notification_settings.create!(notification_type: notification_type)
    end
  end

  private def teacher_notification_settings_info
    teacher_notification_settings.rollup_hash
  end

  private def school_account_info
    return school if school&.name

    School.find_by(name: School::NO_SCHOOL_SELECTED_SCHOOL_NAME)
  end

  private def school_type_account_info
    return (School::ALTERNATIVE_SCHOOLS_DISPLAY_NAME_MAP[school.name] || School::US_K12_SCHOOL_DISPLAY_NAME) if school&.name

    School::US_K12_SCHOOL_DISPLAY_NAME
  end
end
# rubocop:enable Metrics/ClassLength
