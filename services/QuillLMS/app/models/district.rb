# frozen_string_literal: true

# == Schema Information
#
# Table name: districts
#
#  id             :integer          not null, primary key
#  city           :string
#  grade_range    :string
#  name           :string(255)      not null
#  phone          :string
#  state          :string
#  token          :string(255)
#  total_schools  :integer
#  total_students :integer
#  zipcode        :string
#  created_at     :datetime
#  updated_at     :datetime
#  clever_id      :string(255)
#  nces_id        :bigint
#
# Indexes
#
#  index_districts_on_nces_id  (nces_id) UNIQUE
#
class District < ApplicationRecord
  include Subscriber

  validates :name, presence: true
  validates_uniqueness_of :nces_id, allow_blank: true, message: 'A district with this NCES ID already exists.'

  has_many :schools
  has_many :district_admins, dependent: :destroy
  has_many :admins, through: :district_admins, source: :user
  has_many :district_subscriptions
  has_many :subscriptions, through: :district_subscriptions

  scope :by_name, ->(name) { where('name ILIKE ?', "%#{name}%") }
  scope :by_city, ->(city) { where('city ILIKE ?', "%#{city}%") }
  scope :by_state, ->(state) { where(state: state.upcase) }
  scope :by_zipcode, ->(zipcode) { where(zipcode: zipcode) }
  scope :by_nces_id, ->(nces_id) { where(nces_id: nces_id) }
  scope :by_premium_status, ->(premium_status) { joins(:subscriptions).where('subscriptions.account_type = ?', premium_status) }

  def attach_subscription(subscription)
    district_subscriptions.create(subscription: subscription)
  end

  def total_invoice
    schools.sum { |s| s&.subscription&.payment_amount || 0 } / 100.0
  end

  def premium?
    subscription&.present?
  end
end
