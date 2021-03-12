# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

# For expiring and recently created recordings.

class RecordingNotificationWorker < BaseWorker

    def self.perform
      # create activities for recordings expiring and notify the ones created
      notify_recordings_expiring
      #remove_expired_recordings
    end
  
    def self.notify_recordings_expiring
      recordings = expiring_candidates
      recordings.find_each do |rec|
        rec.new_activity_recording_expiration if rec.expiring?
      end
    end
  
    # Remove recordings that expired and that have already sent out a notification
    #def self.remove_expired_recordings
    #  recordings = expiring_candidates
    # recordings.find_each do |rec|
    #    activity = RecentActivity.find_by(trackable: rec, key: 'bigbluebutton_recording.expiration_0')
    #    if activity.present?
    #      notifications = Notification.where(recent_activity_id: activity.id)
    #      notified = notifications.select{ |o| o.notified == false }.blank?
    #     if rec.expired? && notified
    #        rec.delete_from_server!
    #        rec.destroy
    #      end
    #    end
    #  end
    #end
  
    private
  
    def self.expiring_candidates
      # go a little further back in time to make sure we won't miss recordings if this worker is
      # not running all the time
      margin = Rails.application.config.recordings_expiration_candidates_margin 
      not_before = DateTime.now - Rails.application.config.recordings_expiration_months.months - margin
      not_after = not_before + margin + Rails.application.config.recordings_expiration_warnings[0].days + margin
  
      BigbluebuttonRecording
        .where("start_time >= ?", not_before.to_i)
        .where("start_time <= ?", not_after.to_i)
    end
  end
  