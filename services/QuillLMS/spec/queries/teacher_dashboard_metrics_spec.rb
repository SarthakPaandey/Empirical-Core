# frozen_string_literal: true

require 'rails_helper'

describe TeacherDashboardMetrics do
  subject { described_class.new(teacher).run }

  let!(:teacher) { create(:teacher) }
  let!(:classroom1) { create(:classroom_with_one_student, :with_no_teacher) }
  let!(:classroom2) { create(:classroom_with_a_couple_students, :with_no_teacher) }
  let!(:classrooms_teacher1) { create(:classrooms_teacher, user: teacher, classroom: classroom1, role: 'owner') }
  let!(:classrooms_teacher2) { create(:classrooms_teacher, user: teacher, classroom: classroom2, role: 'owner') }
  let!(:unit1) { create(:unit) }
  let!(:unit_activities1) { create_list(:unit_activity, 3, unit: unit1) }
  let!(:unit2) { create(:unit) }
  let!(:unit_activities2) { create_list(:unit_activity, 4, unit: unit2) }
  let(:today) { Date.current }
  let(:july_second_of_this_year) { Date.parse("02-07-#{today.year}") }

  let(:last_july_second) do
    today.month > 7 ? july_second_of_this_year : july_second_of_this_year - 1.year
  end

  around do |example|
    travel_to(1.month.from_now) if Time.current.month == 7
    example.run
    travel_back
  end

  before do
    older_classroom_unit1 = ClassroomUnit.create(classroom_id: classroom1.id, assigned_student_ids: classroom1.students.ids, created_at: last_july_second, unit: unit1)
    older_classroom_unit2 = ClassroomUnit.create(classroom_id: classroom2.id, assigned_student_ids: classroom2.students.ids, created_at: last_july_second, unit: unit1)
    newer_classroom_unit1 = ClassroomUnit.create(classroom_id: classroom1.id, assigned_student_ids: classroom1.students.ids, created_at: today, unit: unit2)
    newer_classroom_unit2 = ClassroomUnit.create(classroom_id: classroom2.id, assigned_student_ids: classroom2.students.ids, created_at: today, unit: unit2)
    ActivitySession.create(user: classroom1.students.first, classroom_unit: older_classroom_unit1, completed_at: last_july_second, activity: UnitActivity.first.activity)
    ActivitySession.create(user: classroom2.students.first, classroom_unit: older_classroom_unit2, completed_at: last_july_second, activity: UnitActivity.first.activity)
    ActivitySession.create(user: classroom2.students.last, classroom_unit: older_classroom_unit2, completed_at: last_july_second, activity: UnitActivity.first.activity)
    ActivitySession.create(user: classroom1.students.first, classroom_unit: older_classroom_unit1, completed_at: last_july_second, activity: UnitActivity.last.activity)
    ActivitySession.create(user: classroom2.students.first, classroom_unit: older_classroom_unit2, completed_at: last_july_second, activity: UnitActivity.last.activity)
    ActivitySession.create(user: classroom2.students.last, classroom_unit: older_classroom_unit2, completed_at: last_july_second, activity: UnitActivity.last.activity)
    ActivitySession.create(user: classroom1.students.first, classroom_unit: newer_classroom_unit1, completed_at: today, activity: UnitActivity.first.activity)
    ActivitySession.create(user: classroom2.students.first, classroom_unit: newer_classroom_unit2, completed_at: today, activity: UnitActivity.first.activity)
    ActivitySession.create(user: classroom2.students.last, classroom_unit: newer_classroom_unit2, completed_at: today, activity: UnitActivity.first.activity)
  end

  describe '#queries' do
    it { expect(subject[:weekly_assigned_activities_count]).to eq(12) }
    it { expect(subject[:weekly_completed_activities_count]).to eq(3) }
    it { expect(subject[:yearly_assigned_activities_count]).to eq(21) }
    it { expect(subject[:yearly_completed_activities_count]).to eq(9) }

    context 'when a unit is archived' do
      before { unit2.update(visible: false) }

      it { expect(subject[:weekly_assigned_activities_count]).to eq(12) }
      it { expect(subject[:weekly_completed_activities_count]).to eq(3) }
      it { expect(subject[:yearly_assigned_activities_count]).to eq(21) }
      it { expect(subject[:yearly_completed_activities_count]).to eq(9) }
    end
  end
end
