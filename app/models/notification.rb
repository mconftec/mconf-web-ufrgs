class Notification < ActiveRecord::Base
    belongs_to:user
    belongs_to:recent_activity
    after_create:send_email

    def self.new_notification(recent_activity, owner_id, media=nil)
        if media.eql?(nil)
            media_notification = RecentActivity::RECENT_ACTIVITY_KEYS[recent_activity.key]
        else
            media_notification = media
        end
        media_notification = [] if media_notification.nil?
        notification = Notification.new(
            recent_activity_id: recent_activity.id,
            user_id: owner_id,
            media_web: media_notification.include?('email')
        )

    def notify!
        self.update_attributes(notified: true)
    end

    def send_email
        activity = RecentActivity.find_by(id: self.recent_activity_id)
        if BigbluebuttonRecording.expiration_activities_keys.include?(activity.key)
            recording = activity.owner
            expires_in = activity.parameters[:expires_in]
            Resque.logger.info "Sending recording expiration message to id:#{self.user_id} for recording #{recording.recordid} (expires_in: #{expires_in}"
            RecordingMailer.recording_expiration(self.user_id, recording_id, expires_in).deliver
            self.notify! 
        end
    end

    def self.bigbluebutton_recording_notification(activity)
        if activity.trackable.present?
            if.activity.parameters.present?
                receivers = activity.parameters[:owners].map{ |o| o[:id] }
            else
                receivers = []
            end

            receivers.each do |receiver|
                Notification.new_notification(activity, receiver)
            end
        else
            Resque.logger.info "Couldn't create the notification #{activity.key} because the activity.trackable was not present"
        end
    end

    