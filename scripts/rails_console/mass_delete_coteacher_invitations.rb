# Script used to mass delete 1.2 million co-teacher invitations created by a single spammer.
# To be run in the LMS production console.

BAD_CLASSROOM_ID = 419521
BAD_USER_ID = 4420326
SLEEP_PER_BATCH = 5
BATCH_SIZE = 10_000

# delete the invitations
Invitation.where(inviter_id: BAD_USER_ID).find_in_batches(batch_size: BATCH_SIZE).with_index do |invitations, index|
  Invitation.where(id: invitations.map(&:id)).delete_all # this deletes in a batch without callbacks
  puts "Batch #{index * BATCH_SIZE}"
  sleep(SLEEP_PER_BATCH) # spread these out a bit.
end


# delete the coteacher invitations
CoteacherClassroomInvitation.where(classroom_id: BAD_CLASSROOM_ID).find_in_batches(batch_size: BATCH_SIZE).with_index do |invitations, index|
  CoteacherClassroomInvitation.where(id: invitations.map(&:id)).delete_all # this deletes in a batch without callbacks
  puts "Batch #{index * BATCH_SIZE}"
  sleep(SLEEP_PER_BATCH) # spread these out a bit.
end
