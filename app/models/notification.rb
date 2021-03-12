class Notification < ActiveRecord::Base
    after_create:send_email


def notify!
    self.update_attributes(notified: true)
end
def send_email
    if BigbluebuttonRecording.expiration_activities_keys.include?(activity.key)
        recording = activity.owner
        expires_in = activity.parameters[:expires_in]
        Resque.logger.info "Sending recording expiration message to id:#{self.user_id} for recording #{recording.recordid} (expires_in: #{expires_in}"
        #RecordingMailer
        self.notify! 
    end
end