class RecordingMailer < BaseMailer
    
  #If the recording is expiring, creates the email to notify the user
  def recording_expiration(user_id, recording_id, expires_in)

    @recording = BigbluebuttonRecording.find_by(recording_id)
    @expires_in = expires_in
    @user = User.find(user_id)

    I18n.with_locale(default_email_locale(@user, nil)) do
        if @expires_in <= 0
          @subject = t("recording_mailer.recording_expiration.subject.expired", room: @recording.room.name).html_safe
        else
          @subject = t("recording_mailer.recording_expiration.subject.expiring", room: @recording.room.name).html_safe
        end
        create_email(@user.email, Site.current.smtp_sender, @subject)
      end
  end
end  