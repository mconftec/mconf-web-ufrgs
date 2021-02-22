class AddOptimizationIndexes3 < ActiveRecord::Migration
  def change
    add_index :bigbluebutton_playback_formats, :recording_id, using: 'btree',
              name: 'index_bigbluebutton_playback_formats_on_recording_id'
    add_index :bigbluebutton_playback_formats, :playback_type_id, using: 'btree',
              name: 'index_bigbluebutton_playback_formats_on_playback_type_id'
    add_index :roles, :stage_type, using: 'btree',
              name: 'index_roles_on_stage_type'

    # duplicated index
    remove_index :permissions, name: "index_permissions_on_subject_id_subject_type"
  end
end
