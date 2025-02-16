# frozen_string_literal: true

# == Schema Information
#
# Table name: canvas_accounts
#
#  id                 :bigint           not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  canvas_instance_id :bigint           not null
#  external_id        :string           not null
#  user_id            :bigint           not null
#
# Indexes
#
#  index_canvas_accounts_on_canvas_instance_id_and_external_id  (canvas_instance_id,external_id) UNIQUE
#  index_canvas_accounts_on_user_id                             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (canvas_instance_id => canvas_instances.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :canvas_account do
    external_id { Faker::Number.number.to_s }
    user
    canvas_instance
  end
end
