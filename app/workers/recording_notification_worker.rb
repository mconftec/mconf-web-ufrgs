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
      check_recordings_expiring
      notify_recordings_expiring
    end
  
    def self.check_recordings_expiring
      recordings = expiring_candidates
      recordings.find_each do |rec|
        rec.new_activity_recording_expiration if rec.expiring?
      end
    end
  
    def self.notify_recordings_expiring
      recordings = expiring_candidates
      recordings.find_each do |rec|
        activity = RecentActivity.find_by(trackable: rec, key: 'bigbluebutton_recording_expiration_1')
        if activity.present?
          owners = activity.parameters[:owners]
          owners.for_each do | owner |
            Resque.logger.info "Sending user registered email to #{owner.id}"
            UserMailer.recording_expiring_email(owner.id)
          end
        end
      end
    end
  
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
end
