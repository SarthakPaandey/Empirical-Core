require 'rails_helper'

describe 'SerializeVitallySalesAccount' do
  let(:school) do
    create(:school,
      name: 'Kool School',
      mail_city: 'New York',
      mail_state: 'NY',
      mail_zipcode: '11104',
      leanm: 'Kool District',
      phone: '555-666-3210',
      charter: 'N',
      free_lunches: 0,
      ppin: nil,
      nces_id: '111111111',
      ulocal: '41'
    )
  end

  it 'includes the accountId' do
    school_data = SerializeVitallySalesAccount.new(school).data

    expect(school_data).to include(accountId: school.id.to_s)
  end

  it 'generates basic school params' do

    school_data = SerializeVitallySalesAccount.new(school).data

    expect(school_data[:traits]).to include(
      name: 'Kool School',
      city: 'New York',
      state: 'NY',
      zipcode: '11104',
      district: 'Kool District',
      phone: '555-666-3210',
      charter: 'N',
      frl: 0,
      ppin: nil,
      nces_id: '111111111',
      school_subscription: 'NA',
      school_type: 'Rural, Fringe',
      employee_count: 0,
      paid_teacher_subscriptions: 0,
      active_students: 0,
      active_students_this_year: 0,
      total_students: 0,
      total_students_this_year: 0,
      activities_finished_this_year: 0,
      activities_per_student: 0,
      activities_per_student_this_year: 0,
      activities_finished: 0,
      school_link: "https://www.quill.org/cms/schools/#{school.id}"
    )
  end

  it 'generates school premium status' do
    school_subscription = create(:subscription,
      account_type: 'SUPER SAVER PREMIUM',
      expiration: Date.tomorrow
    )
    create(:school_subscription,
      subscription_id: school_subscription.id,
      school_id: school.id
    )

    school_data = SerializeVitallySalesAccount.new(school).data

    expect(school_data[:traits]).to include(
      school_subscription: 'SUPER SAVER PREMIUM'
    )
    expect(school_data[:traits]).to include(
      premium_expiry_date: Date.tomorrow
    )
  end

  it 'generates teacher data' do
    teacher_subscription = create(:subscription,
      account_type: 'Teacher Paid'
    )
    teacher_with_subscription = create(:user, role: 'teacher')
    create(:user_subscription,
      subscription: teacher_subscription,
      user: teacher_with_subscription
    )
    school.users << teacher_with_subscription
    school.users << create(:user, role: 'teacher')

    school_data = SerializeVitallySalesAccount.new(school).data

    expect(school_data[:traits]).to include(
      employee_count: 2,
      paid_teacher_subscriptions: 1,
      active_students: 0,
      activities_finished: 0
    )
  end

  it 'generates student data' do
    active_student = create(:user, role: 'student', last_sign_in: Date.today)
    active_old_student = create(:user, role: 'student', last_sign_in: Date.today - 2.year)
    inactive_student = create(:user, role: 'student', last_sign_in: Date.today - 2.year)
    teacher = create(:user, role: 'teacher')
    classroom = create(:classroom)
    classroom_unit = create(:classroom_unit, classroom: classroom)
    old_classroom_unit = create(:classroom_unit, classroom: classroom)
    create(:classrooms_teacher, user: teacher, classroom: classroom)
    create(:students_classrooms, student: active_student, classroom: classroom)
    create(:students_classrooms, student: inactive_student, classroom: classroom)
    create(:students_classrooms, student: active_old_student, classroom: classroom)
    create(:activity_session,
      user: active_student,
      classroom_unit: classroom_unit,
      state: 'finished'
    )
    create(:activity_session,
      user: active_old_student,
      classroom_unit: old_classroom_unit,
      state: 'finished',
      updated_at: Time.now - 2.year
    )
    last_activity_session = create(:activity_session,
      user: active_student,
      classroom_unit: classroom_unit,
      state: 'finished'
    )
    school.users << active_student
    school.users << inactive_student
    school.users << teacher
    school.users << create(:user, role: 'student')

    school_data = SerializeVitallySalesAccount.new(school).data

    expect(school_data[:traits]).to include(
      active_students: 2,
      active_students_this_year: 1,
      total_students: 3,
      total_students_this_year: 1,
      activities_finished: 3,
      activities_finished_this_year: 2,
      activities_per_student: 1.5,
      activities_per_student_this_year: 2.0
    )
    expect(school_data[:traits][:last_active]).to be_within(0.000001.second).of(last_activity_session.completed_at)
  end
end