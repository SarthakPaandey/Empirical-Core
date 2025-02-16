# frozen_string_literal: true

require 'rails_helper'

describe SendSalesFormSubmissionToSlackWorker do
  subject { described_class.new }

  let(:sales_form_submission) { create(:sales_form_submission) }

  describe '#perform' do
    it 'sends a Slack message' do
      stub_url = 'fake_slack_url'
      # We only actually try to send messages if SlackTasks::LIVE is true
      stub_const('SlackTasks::LIVE', true)
      stub_const('ENV', { 'SLACK_API_WEBHOOK_SALES' => stub_url })
      expect(HTTParty).to receive(:post).with(stub_url, anything)

      subject.perform(sales_form_submission.id)
    end
  end
end
