# frozen_string_literal: true

class PremiumHub::MadeSchoolAdminChangeSchoolEmailWorker
  include Sidekiq::Worker

  def perform(user_id, admin_user_id, new_school_id, existing_school_id)
    user = User.find_by(id: user_id)
    admin_name = User.find_by(id: admin_user_id)&.name
    new_school = School.find_by(id: new_school_id)
    existing_school = School.find_by(id: existing_school_id)

    return unless user && admin_name && new_school && existing_school

    if user.is_admin_for_one_school?
      user.mailer_user.send_premium_hub_made_school_admin_change_school_email(admin_name, new_school, existing_school)
    end

    Analytics::SegmentAnalytics.new.track_school_admin_user(
      user,
      Analytics::SegmentIo::BackgroundEvents::ADMIN_MADE_EXISTING_USER_SCHOOL_ADMIN,
      new_school.name,
      admin_name
    )
  end
end
