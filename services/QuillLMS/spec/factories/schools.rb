# frozen_string_literal: true

# == Schema Information
#
# Table name: schools
#
#  id                    :integer          not null, primary key
#  charter               :string(255)
#  city                  :string(255)
#  direct_certification  :integer
#  ethnic_group          :string(255)
#  free_lunches          :integer
#  fte_classroom_teacher :integer
#  latitude              :decimal(9, 6)
#  longitude             :decimal(9, 6)
#  lower_grade           :integer
#  magnet                :string(255)
#  mail_city             :string(255)
#  mail_state            :string(255)
#  mail_street           :string(255)
#  mail_zipcode          :string(255)
#  name                  :string(255)
#  nces_status_code      :string(255)
#  nces_type_code        :string(255)
#  phone                 :string(255)
#  ppin                  :string
#  school_level          :integer
#  state                 :string(255)
#  street                :string(255)
#  total_students        :integer
#  ulocal                :integer
#  upper_grade           :integer
#  zipcode               :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  authorizer_id         :integer
#  clever_id             :string(255)
#  coordinator_id        :integer
#  district_id           :bigint
#  nces_id               :string(255)
#
# Indexes
#
#  index_schools_on_district_id     (district_id)
#  index_schools_on_mail_zipcode    (mail_zipcode)
#  index_schools_on_name            (name)
#  index_schools_on_nces_id         (nces_id)
#  index_schools_on_state           (state)
#  index_schools_on_zipcode         (zipcode)
#  unique_index_schools_on_nces_id  (nces_id) UNIQUE WHERE ((nces_id)::text <> ''::text)
#  unique_index_schools_on_ppin     (ppin) UNIQUE WHERE ((ppin)::text <> ''::text)
#
FactoryBot.define do
  factory :simple_school, class: 'School'

  factory :school do
    sequence(:nces_id, 100000000000)
    mail_street { '123 Broadway' }
    mail_city { 'New York City' }
    mail_state { 'NY' }
    mail_zipcode { '10003' }
    street { mail_street }
    city { mail_city }
    state { mail_state }
    zipcode { mail_zipcode }
    sequence(:name) { |n| "#{mail_city} School #{n}" }
    phone { '1-800-555-1234' }
    longitude { '-74.044500' }
    latitude { '40.689249' }
    free_lunches { 50 }
    nces_status_code { 3 }
    nces_type_code { 6 }
    lower_grade { 5 }
    upper_grade { 8 }

    trait :private_school do
      nces_id { nil }
      nces_type_code { nil }
      nces_status_code { nil }
      free_lunches { nil }
      total_students { 1500 }
      fte_classroom_teacher { 100 }
      ppin { 'A1234567' }
    end
  end
end
