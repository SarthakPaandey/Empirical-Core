# frozen_string_literal: true

require 'rails_helper'

describe SetImpactMetricsWorker do
  subject { described_class.new }

  context '#perform' do
    let(:activity_sessions) { create_list(:activity_session, 10) }

    let(:activity_sessions_payload) {
      [{ count: activity_sessions.length }]
    }

    let(:active_students_payload) { [{ count: activity_sessions.length }] }

    let(:teachers) { create_list(:teacher, 15) }

    let(:teachers_payload) {
      [{ :count => 3 }]
    }

    let(:schools_payload) {
      [
        { id: 333, free_lunches: 30 },
        { id: 334, free_lunches: 0 },
        { id: 545, free_lunches: 54 }
      ]
    }

    before do
      allow(ImpactMetrics::ActivitiesAllTimeQuery).to receive(:run).and_return(activity_sessions_payload)
      allow(ImpactMetrics::ActiveStudentsAllTimeQuery).to receive(:run).and_return(active_students_payload)
      allow(ImpactMetrics::ActiveTeachersAllTimeCountQuery).to receive(:run).and_return(teachers_payload)
      allow(ImpactMetrics::SchoolsWithMinimumActivitySessionsQuery).to receive(:run).and_return(schools_payload)
    end

    it 'should set the NUMBER_OF_SENTENCES redis value' do
      subject.perform
      expect($redis.get(PagesController::NUMBER_OF_SENTENCES)).to eq((SetImpactMetricsWorker.round_to_hundred_millions(activity_sessions_payload.size * SetImpactMetricsWorker::SENTENCES_PER_ACTIVITY_SESSION)).to_s)
    end

    it 'should set the NUMBER_OF_STUDENTS redis value' do
      subject.perform
      expect($redis.get(PagesController::NUMBER_OF_STUDENTS)).to eq((SetImpactMetricsWorker.round_to_hundred_thousands(activity_sessions_payload.count('DISTINCT(user_id)'))).to_s)
    end

    it 'should set the NUMBER_OF_TEACHERS redis value' do
      subject.perform
      expect($redis.get(PagesController::NUMBER_OF_TEACHERS)).to eq(SetImpactMetricsWorker.round_to_thousands(teachers.length).to_s)
    end

    it 'should set the NUMBER_OF_SCHOOLS redis value' do
      subject.perform
      expect($redis.get(PagesController::NUMBER_OF_SCHOOLS)).to eq(SetImpactMetricsWorker.round_to_thousands(schools_payload.length).to_s)
    end

    it 'should set the NUMBER_OF_LOW_INCOME_SCHOOLS redis value' do
      subject.perform
      number_of_schools = SetImpactMetricsWorker.round_to_thousands(schools_payload.length)
      expect($redis.get(PagesController::NUMBER_OF_LOW_INCOME_SCHOOLS)).to eq(SetImpactMetricsWorker.round_to_thousands((number_of_schools * SetImpactMetricsWorker::LOW_INCOME_PERCENTAGE)).to_s)
    end
  end
end
