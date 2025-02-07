# frozen_string_literal: true

require 'rails_helper'

module Snapshots
  describe ActivitiesCompletedQuery do
    context 'external_api', :big_query_snapshot do
      include_context 'Snapshots Activity Session Count CTE'

      let(:num_completed_activities) { activity_sessions.count }

      it { expect(results).to eq(count: num_completed_activities) }
    end
  end
end
