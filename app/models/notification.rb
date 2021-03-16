class Notification < ActiveRecord::Base
    belongs_to:user
    belongs_to:recent_activity
    after_create:send_email

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