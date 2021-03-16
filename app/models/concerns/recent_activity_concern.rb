module RecentActivityConcern
    extend ActiveSupport::Concern

    included do
        after_create: create_notification
    end

    def create_notification
        if BigbluebuttonRecording.expiration_activities_keys.include?(self.key)
            Notification.bigbluebutton_recording_notification(self)
        end
    end
end