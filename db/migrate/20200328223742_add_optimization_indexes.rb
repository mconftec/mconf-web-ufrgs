class AddOptimizationIndexes < ActiveRecord::Migration
  def change
    add_index :activities, [:key], using: 'btree',
              name: 'activities_key_IDX'

    add_index :permissions, [:user_id, :subject_type], using: 'btree',
              name: 'permissions_user_id_IDX'

    add_index :permissions, [:user_id, :subject_type, :subject_id], using: 'btree',
              name: 'permissions_user_id_IDX_02'

    add_index :profiles, [:user_id], using: 'btree',
              name: 'profiles_user_id_IDX'

    add_index :users, [:disabled], using: 'btree',
              name: 'users_disabled_IDX'

    add_index :bigbluebutton_meetings, [:room_id, :create_time], using: 'btree',
              name: 'bigbluebutton_meetings_room_id_IDX'

    add_index :bigbluebutton_rooms, [:param], using: 'btree',
              name: 'bigbluebutton_rooms_param_IDX'

    add_index :bigbluebutton_metadata, [:owner_id, :owner_type, :name], using: 'btree',
              name: 'bigbluebutton_metadata_owner_id_IDX'
  end
end
