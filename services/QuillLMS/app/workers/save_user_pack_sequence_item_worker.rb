# frozen_string_literal: true

class SaveUserPackSequenceItemWorker
  include Sidekiq::Worker

  sidekiq_options queue: SidekiqQueue::CRITICAL

  def perform(pack_sequence_item_id, status, user_id)
    return if pack_sequence_item_id.nil? || user_id.nil?
    return unless PackSequenceItem.exists?(id: pack_sequence_item_id)
    return unless User.exists?(id: user_id)

    upsi = UserPackSequenceItem.create_or_find_by!(pack_sequence_item_id: pack_sequence_item_id, user_id: user_id)
    return if upsi.status == status

    upsi.update!(status: status)

  # While create_or_find_by! runs a race condition with pack sequence item destroyed elsewhere
  rescue ActiveRecord::InvalidForeignKey
    retry
  end
end
