# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Demo::ReportDemoCreator do
  context 'ACTIVITY_PACKS_TEMPLATES config' do
    let(:expected_keys) { [:activity_sessions, :name, :unit_template_id] }

    subject { described_class::ACTIVITY_PACKS_TEMPLATES }

    it { expect(subject.class).to be Array }
    it { expect(subject.all? { |template| template.keys.sort == expected_keys }).to be true }
    it { expect(subject.all? { |template| template[:activity_sessions].instance_of?(Array) }).to be true }
    it { expect(subject.all? { |template| template[:activity_sessions].map(&:keys).flatten.all? { |k| k.instance_of?(Integer) } }).to be true }
    it { expect(subject.all? { |template| template[:activity_sessions].map(&:values).flatten.all? { |v| v.instance_of?(Integer) } }).to be true }
  end

  context 'full data set' do
    before do
      described_class::ACTIVITY_PACKS_TEMPLATES
        .map { |template| described_class.activity_ids_for_config(template) }
        .flatten
        .uniq
        .each { |activity_id| create(:activity, id: activity_id) }

      Demo::SessionData.new
        .concept_results
        .map(&:concept_id)
        .uniq
        .each { |concept_id| create(:concept, id: concept_id) }
    end

    describe 'create_demo' do
      let(:demo_teacher) { User.find_by(email: 'hello+demoteacher@quill.org') }

      it 'should create teacher and classroom with activity' do
        expect(SaveActivitySessionConceptResultsWorker).to receive(:perform_async).exactly(Demo::SessionData.new.concept_results.length).times

        described_class.create_demo

        expect(demo_teacher.classrooms_i_teach.count).to eq(1)
        classroom = demo_teacher.classrooms_i_teach.first

        expect(classroom.students.count).to eq(5)
        expect(classroom.activity_sessions.count).to eq(Demo::SessionData.new.activity_sessions.length)
      end
    end
  end

  context 'demo data set' do
    let!(:teacher) { create(:teacher) }
    let(:session_data) { Demo::SessionData.new }
    # essentially using these as fixtures to test the demo data
    let(:activity_id) { described_class::STARTER_BASELINE_DIAGNOSTIC_PRE_ACTIVITY_ID }
    let(:user_id) { described_class::KEN_ID }
    let!(:activity) { create(:activity, id: activity_id) }

    let(:concept_ids) { [566, 506, 508, 641, 640, 671, 239, 551, 488, 385, 524, 540, 664, 83, 673, 450] }
    let!(:concepts) { concept_ids.map { |id| create(:concept, id: id) } }

    let(:demo_config) do
      [
        {
          name: 'Quill Activity Pack',
          activity_sessions: [
            { activity_id => user_id },
            { activity_id => user_id },
            { activity_id => user_id },
            { activity_id => user_id },
            { activity_id => user_id }
          ]
        }
      ]
    end

    let(:is_teacher_demo) { true }

    before do
      stub_const('Demo::ReportDemoCreator::ACTIVITY_PACKS_TEMPLATES', demo_config)
      stub_const('Demo::ReportDemoCreator::REPLAYED_ACTIVITY_ID', activity_id)
      stub_const('Demo::ReportDemoCreator::REPLAYED_SAMPLE_USER_ID', user_id)
    end

    it 'creates a teacher with name' do
      email = 'hello+demoteacher@quill.org'
      Demo::ReportDemoCreator.create_teacher(email)
      teacher = User.find_by(name: 'Demo Teacher')
      expect(teacher.name).to eq('Demo Teacher')
      expect(teacher.email).to eq(email)
      expect(teacher.role).to eq('teacher')
      expect(teacher.flags).to eq(['beta'])
    end

    it 'creates a classroom for the teacher' do
      Demo::ReportDemoCreator.create_classroom(teacher)
      classroom = teacher.classrooms_i_teach.find { |c| c.name == 'Quill Classroom' }

      expect(classroom.code).to eq("demo-#{teacher.id}")
      expect(classroom.grade).to eq('9')
      expect(teacher.classrooms_i_teach.include?(classroom)).to eq(true)
    end

    it 'creates units' do
      Demo::ReportDemoCreator.create_units(teacher, is_teacher_demo)
      Demo::ReportDemoCreator::ACTIVITY_PACKS_TEMPLATES.each do |unit_obj|
        unit = Unit.find_by(name: unit_obj[:name])
        activity_ids = Demo::ReportDemoCreator.activity_ids_for_config(unit_obj)
        expect(unit).to be
        expect(UnitActivity.find_by(unit_id: unit.id, activity_id: activity_ids[0])).to be
      end
    end

    it 'creates subscription' do
      Demo::ReportDemoCreator.create_subscription(teacher)
      expect(teacher.subscription.purchaser_id).to eq(teacher.id)
      expect(teacher.subscription.account_type).to eq('Teacher Trial')
    end

    it 'create classroom units' do
      student = create(:student)
      students = [student]
      units = Demo::ReportDemoCreator.create_units(teacher, is_teacher_demo)
      classroom = create(:classroom)
      create(:students_classrooms, student: student, classroom: classroom)
      create(:classrooms_teacher, classroom: classroom, user: teacher)
      Demo::ReportDemoCreator.create_classroom_units(classroom, units)
      units.each do |unit|
        expect(ClassroomUnit.find_by(classroom_id: classroom.id, unit_id: unit.id, assign_on_join: true, assigned_student_ids: [student.id])).to be
      end
    end

    context 'create students' do
      let(:classroom) { create(:classroom) }
      let(:student_names) { ['Angie Thomas', 'Jason Reynolds', 'Ken Liu', 'Nic Stone', 'Tahereh Mafi'] }
      let(:angie_email) { 'angie_thomas_demo@quill.org' }
      let(:demo_password) { described_class::PASSWORD }

      subject { classroom.students }

      context 'teacher-facing' do
        before { Demo::ReportDemoCreator.create_students(classroom, true, Demo::ReportDemoCreator::STUDENT_TEMPLATES) }

        it { expect(subject.count).to eq 5 }
        it { expect(subject.map(&:name).sort).to eq student_names }
        it { expect(subject.find_by(name: 'Angie Thomas').username).to eq "angie.thomas.#{classroom.id}@demo-teacher" }
        it { expect(subject.all? { |s| s.authenticate(demo_password) }).to be true }
        it { expect(subject.exists?(email: angie_email)).to be true }
      end

      context 'not teacher-facing' do
        before { Demo::ReportDemoCreator.create_students(classroom, false, Demo::ReportDemoCreator::STUDENT_TEMPLATES) }

        it { expect(subject.count).to eq 5 }
        it { expect(subject.map(&:name).sort).to eq student_names }
        it { expect(subject.find_by(name: 'Angie Thomas').username).to eq "angie.thomas.#{classroom.id}@demo-teacher" }
        it { expect(subject.all? { |s| s.authenticate(demo_password) }).to be true }
        it { expect(subject.exists?(email: angie_email)).to be false }
      end
    end

    it 'creates activity sessions' do
      Sidekiq::Testing.inline! do
        session_clone = session_data.activity_sessions
          .find { |session| session.activity_id == activity_id && session.user_id == user_id }

        student = create(:student)
        classroom = create(:classroom, :with_no_teacher)
        create(:classrooms_teacher, classroom: classroom, user: teacher)
        create(:students_classrooms, student: student, classroom: classroom)
        units = Demo::ReportDemoCreator.create_units(teacher, is_teacher_demo)

        Demo::ReportDemoCreator.create_classroom_units(classroom, units)

        total_act_sesh_count = Demo::ReportDemoCreator::ACTIVITY_PACKS_TEMPLATES.map { |ap| ap[:activity_sessions][0].keys.count }.sum

        expect { Demo::ReportDemoCreator.create_activity_sessions([student], classroom, session_data, is_teacher_demo) }
          .to change { ActivitySession.count }
          .by(total_act_sesh_count)

        activity_session = ActivitySession.last

        last_template = Demo::ReportDemoCreator::ACTIVITY_PACKS_TEMPLATES.last
        expect(activity_session.activity_id).to eq(last_template[:activity_sessions][0].keys.last)
        expect(activity_session.user_id).to eq(student.id)
        expect(activity_session.state).to eq('finished')

        expect(activity_session.percentage).to eq(session_clone.percentage)
        expect(activity_session.timespent).to eq(session_clone.timespent || Demo::ReportDemoCreator::DEFAULT_TIMESPENT)
        expect(activity_session.concept_results.first.extra_metadata.keys).to match_array ['cues', 'question_uid', 'question_concept_uid']
        # Taken from actual concept_result
        expect(activity_session.concept_results.first.answer).to eq("Even though it's cover is torn and it's pages are yellowed, the book is very valuable because it's three hundred years old and very rare.")
      end
    end

    describe '#reset_account' do
      before do
        stub_const('Demo::ReportDemoCreator::UNITS_COUNT', 1)

        Demo::ReportDemoCreator.create_demo_classroom_data(teacher, is_teacher_demo: true)
      end

      subject { Demo::ReportDemoCreator.reset_account(teacher.id) }

      it 'should create expected counts for untouched account' do
        expect { subject }
          .to not_change { teacher.reload.google_id }.from(nil)
          .and not_change { teacher.reload.clever_id }.from(nil)
          .and not_change { teacher.classrooms_i_teach.count }.from(1)
          .and not_change { teacher.classrooms_i_teach.map(&:id) }
          .and not_change { teacher.reload.auth_credential }.from(nil)
      end

      context 'teacher account has added data' do
        let(:teacher) { create(:teacher, google_id: 1234, clever_id: 5678) }
        let!(:auth_credential) { create(:google_auth_credential, user: teacher) }
        let(:classroom) { create(:classroom) }
        let!(:classrooms_teacher) { create(:classrooms_teacher, classroom: classroom, user: teacher) }

        it 'should create expected counts' do
          expect { subject }
            .to change { teacher.reload.google_id }.from('1234').to(nil)
            .and change { teacher.reload.clever_id }.from('5678').to(nil)
            .and change { teacher.reload.classrooms_i_teach.count }.from(2).to(1)
            .and change(AuthCredential, :count).from(1).to(0)
            .and change(Classroom.where(id: classroom.id), :count).from(1).to(0)
            .and not_change(Classroom.unscoped.where(id: classroom.id), :count).from(1)
            .and not_change { Demo::ReportDemoCreator.demo_classroom(teacher.reload).id }
        end
      end

      context 'demo classroom changed' do
        before do
          demo_classroom = teacher.classrooms_i_teach.first
          demo_classroom.update(name: 'my classroom name')
        end

        it { expect { subject }.to change { Demo::ReportDemoCreator.demo_classroom(teacher.reload).id } }

        it 'should not raise an error with two occurences running at once' do
          threads = Array.new(2) do
            Thread.new { subject }.tap { |thread| thread.report_on_exception = false }
          end

          expect { threads.map(&:join) }.to_not raise_error
        end
      end
    end
  end
end
