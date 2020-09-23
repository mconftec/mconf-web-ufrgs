# This migration adds a lot of indexes to the database, most of them to columns that are
# foreign keys (everything `*_id`), or in columns we know are used in lots of searches.
# Some indexes are also renamed to follow the same pattern used by rails.
class AddOptimizationIndexes2 < ActiveRecord::Migration
  def change
    rename_index :activities,
                 'activities_key_IDX',
                 'index_activities_on_key'
    rename_index :bigbluebutton_meetings,
                 'bigbluebutton_meetings_room_id_IDX',
                 'index_bigbluebutton_meetings_on_room_id_create_time'
    add_index :attachments, :space_id, using: 'btree',
              name: 'index_attachments_on_space_id'
    add_index :bigbluebutton_meetings, :server_id, using: 'btree',
              name: 'index_bigbluebutton_meetings_on_server_id'
    add_index :bigbluebutton_meetings, :room_id, using: 'btree',
              name: 'index_bigbluebutton_meetings_on_room_id'
    add_index :bigbluebutton_metadata, [:owner_id, :owner_type], using: 'btree',
              name: 'index_bigbluebutton_metadata_on_owner_id_owner_type'
    add_index :bigbluebutton_recordings, :server_id, using: 'btree',
              name: 'index_bigbluebutton_recordings_on_server_id'
    add_index :bigbluebutton_recordings, :meeting_id, using: 'btree',
              name: 'index_bigbluebutton_recordings_on_meeting_id'
    add_index :bigbluebutton_rooms, [:owner_id, :owner_type], using: 'btree',
              name: 'index_bigbluebutton_rooms_on_owner_id_owner_type'
    rename_index :bigbluebutton_rooms,
                 'bigbluebutton_rooms_param_IDX',
                 'index_bigbluebutton_rooms_on_param'
    add_index :bigbluebutton_servers, :param, using: 'btree',
              name: 'index_bigbluebutton_servers_on_param'
    add_index :join_requests, :request_type, using: 'btree',
              name: 'index_join_requests_on_request_type'
    add_index :join_requests, :candidate_id, using: 'btree',
              name: 'index_join_requests_on_candidate_id'
    add_index :join_requests, :introducer_id, using: 'btree',
              name: 'index_join_requests_on_introducer_id'
    add_index :join_requests, [:group_id, :group_type], using: 'btree',
              name: 'index_join_requests_on_group_id_group_type'
    add_index :join_requests, :role_id, using: 'btree',
              name: 'index_join_requests_on_role_id'
    add_index :join_requests, :secret_token, using: 'btree',
              name: 'index_join_requests_on_secret_token'
    add_index :participant_confirmations, :token, using: 'btree',
              name: 'index_participant_confirmations_on_token'
    add_index :posts, :reader_id, using: 'btree',
              name: 'index_posts_on_reader_id'
    add_index :posts, :space_id, using: 'btree',
              name: 'index_posts_on_space_id'
    add_index :posts, :parent_id, using: 'btree',
              name: 'index_posts_on_parent_id'
    add_index :posts, [:author_id, :author_type], using: 'btree',
              name: 'index_posts_on_author_id_author_type'
    add_index :spaces, :public, using: 'btree',
              name: 'index_spaces_on_public'
    add_index :users, :can_record, using: 'btree',
              name: 'index_users_on_can_record'


    add_index :events, :owner_id, using: 'btree',
              name: 'index_events_on_owner_id'
    add_index :events, :owner_type, using: 'btree',
              name: 'index_events_on_owner_type'
    add_index :events, :start_on, using: 'btree',
              name: 'index_events_on_start_on'
    add_index :events, :end_on, using: 'btree',
              name: 'index_events_on_end_on'
    add_index :events, [:owner_id, :owner_type], using: 'btree',
              name: 'index_events_on_owner_id_owner_type'
    add_index :invitations, :recipient_id, using: 'btree',
              name: 'index_invitations_on_recipient_id'
    add_index :invitations, :sender_id, using: 'btree',
              name: 'index_invitations_on_sender_id'
    add_index :participant_confirmations, :participant_id, using: 'btree',
              name: 'index_participant_confirmations_on_participant_id'
    add_index :participants, :event_id, using: 'btree',
              name: 'fk_participants_event_id'
    add_index :participants, [:owner_id, :owner_type], using: 'btree',
              name: 'index_participants_on_owner_id_owner_type'
    rename_index :permissions,
                 'permissions_user_id_IDX',
                 'index_permissions_on_subject_id_subject_type'
    rename_index :permissions,
                 'permissions_user_id_IDX_02',
                 'index_permissions_on_user_id_subject_type_subject_id'
    # remove_index :permissions, [:user_id, :subject_type, :subject_id], using: 'btree',
                 # name: 'permissions_user_id_IDX_02'
    # add_index :permissions, [:user_id, :subject_type, :subject_id], using: 'btree',
    #           name: 'index_permissions_on_user_id_subject_type_and_others'
    add_index :permissions, [:user_id, :subject_type], using: 'btree',
              name: 'index_permissions_on_user_id_subject_type'
    add_index :permissions, :user_id, using: 'btree',
              name: 'index_permissions_on_user_id'
    add_index :permissions, :role_id, using: 'btree',
              name: 'fk_permissions_role_id'
    add_index :permissions, :subject_id, using: 'btree',
              name: 'index_permissions_on_subject_id'
    add_index :permissions, :subject_type, using: 'btree',
              name: 'index_permissions_on_subject_type'
    add_index :profiles, :full_name, using: 'btree',
              name: 'index_profiles_on_full_name'
    add_index :spaces, :approved, using: 'btree',
              name: 'index_spaces_on_approved'
    add_index :spaces, :disabled, using: 'btree',
              name: 'index_spaces_on_disabled'
    add_index :spaces, :permalink, using: 'btree',
              name: 'index_spaces_on_permalink'
    rename_index :users,
                 'users_disabled_IDX',
                 'index_users_on_disabled'
    add_index :users, :approved, using: 'btree',
              name: 'index_users_on_approved'
    add_index :users, :username, using: 'btree',
              name: 'index_users_on_username'
  end
end
