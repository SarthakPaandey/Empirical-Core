# frozen_string_literal: true

# == Schema Information
#
# Table name: canvas_instances
#
#  id         :bigint           not null, primary key
#  url        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_canvas_instances_on_url  (url) UNIQUE
#
FactoryBot.define do
  factory :canvas_instance do
    url { "https://#{SecureRandom.hex(12)}.instructure.com" }
  end
end