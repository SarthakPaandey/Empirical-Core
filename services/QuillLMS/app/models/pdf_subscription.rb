# frozen_string_literal: true

# == Schema Information
#
# Table name: pdf_subscriptions
#
#  id                               :bigint           not null, primary key
#  frequency                        :string           not null
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  admin_report_filter_selection_id :bigint           not null
#
# Indexes
#
#  index_pdf_subscriptions_on_admin_report_filter_selection_id  (admin_report_filter_selection_id)
#  index_pdf_subscriptions_on_frequency                         (frequency)
#
class PdfSubscription < ApplicationRecord
  FREQUENCIES = [
    WEEKLY = 'weekly',
    MONTHLY = 'monthly'
  ]

  belongs_to :user
  belongs_to :admin_report_filter_selection

  validates :frequency, presence: true, inclusion: { in: FREQUENCIES }
end