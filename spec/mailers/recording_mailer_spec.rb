# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require "spec_helper"
include ApplicationHelper
include CustomBigbluebuttonPlaybackTypesHelper
include DatesHelper
include IconsHelper

describe RecordingMailer do
    let(:recording) { FactoryGirl.create(:bigbluebutton_recording, created_at: DateTime.now) }
    let(:user) { FactoryGirl.create(:unconfirmed_user) }
    let(:url) { "www.test.com" }
    let(:url_playback) { "www.any.org/play" }
  
    # enable recording expiration
    before {
      @expiration = Rails.application.config.recordings_expiration_enabled
      Rails.application.config.recordings_expiration_enabled = true
    }
    after {
      Rails.application.config.recordings_expiration_enabled = @expiration
    }

    describe '.recording_expiration' do
        context "for a recording that is expiring" do
          let(:mail) { RecordingMailer.recording_expiration(user.id, recording.id, 10) }
          let(:room) { FactoryGirl.create(:bigbluebutton_room) }
          let(:recording) { FactoryGirl.create(:bigbluebutton_recording, created_at: DateTime.now, room: room) }
    
          context "for a room of a space" do
            let(:space) { FactoryGirl.create(:space) }
            before {
              room.update_attributes(owner: space)
              allow_any_instance_of( Rails.application.routes.url_helpers ).to receive(:recordings_space_url).and_return(url)
            }
    
            it("sets 'to'") { mail.to.should eql([user.email]) }
            it("sets 'subject'") {
              text = "[#{Site.current.name}] #{I18n.t('recording_mailer.recording_expiration.subject.expiring', room: recording.room.name)}"
              mail.subject.should eql(text)
            }
            it("sets 'from'") { mail.from.should eql([Site.current.smtp_sender]) }
            it("sets 'headers'") { mail.headers.should eql({}) }
            it("assigns @recording") { mail.body.encoded.should match(recording.room.name) }
            it("renders the link to see the recording link {space}") {
              mail.body.encoded.should match(Regexp.escape(url))
            }
            it("renders the link to see the recordings playbacks") {
              allow_any_instance_of(CustomBigbluebuttonPlaybackTypesHelper).to receive(:link_to_playback).and_return(url_playback)
              mail.body.encoded.should match(Regexp.escape(url))
            }
            it { mail.body.encoded.should match(format_date(recording.created_at, :long)) }
            it { mail.body.encoded.should match(format_date(recording.expiration_date, :long, false)) }
          end
    
          context "for a room of a user" do
            let(:user) { FactoryGirl.create(:user) }
            before {
              room.update_attributes(owner: user)
              allow_any_instance_of( Rails.application.routes.url_helpers ).to receive(:my_recordings_url).and_return(url)
            }
    
            it("sets 'to'") { mail.to.should eql([user.email]) }
            it("sets 'subject'") {
              text = "[#{Site.current.name}] #{I18n.t('recording_mailer.recording_expiration.subject.expiring', room: recording.room.name)}"
              mail.subject.should eql(text)
            }
            it("sets 'from'") { mail.from.should eql([Site.current.smtp_sender]) }
            it("sets 'headers'") { mail.headers.should eql({}) }
            it("assigns @recording") { mail.body.encoded.should match(recording.room.name) }
            it("renders the link to see the recording link {space}") {
              mail.body.encoded.should match(Regexp.escape(url))
            }
            it("renders the link to see the recordings playbacks") {
              allow_any_instance_of(CustomBigbluebuttonPlaybackTypesHelper).to receive(:link_to_playback).and_return(url_playback)
              mail.body.encoded.should match(Regexp.escape(url))
            }
            it { mail.body.encoded.should match(format_date(recording.created_at, :long)) }
            it { mail.body.encoded.should match(format_date(recording.expiration_date, :long, false)) }
          end
        end
    
        context "for a recording that expired" do
          let(:mail) { RecordingMailer.recording_expiration(user.id, recording.id, 0) }
          let(:room) { FactoryGirl.create(:bigbluebutton_room) }
          let(:recording) { FactoryGirl.create(:bigbluebutton_recording, created_at: DateTime.now, room: room) }
    
          context "for a room of a space" do
            let(:space) { FactoryGirl.create(:space) }
            before {
              room.update_attributes(owner: space)
              Rails.application.routes.url_helpers.should_not_receive(:space_recordings_url)
              CustomBigbluebuttonPlaybackTypesHelper.should_not_receive(:link_to_playback)
            }
    
            it("sets 'to'") { mail.to.should eql([user.email]) }
            it("sets 'subject'") {
              text = "[#{Site.current.name}] #{I18n.t('recording_mailer.recording_expiration.subject.expired', room: recording.room.name)}"
              mail.subject.should eql(text)
            }
            it("sets 'from'") { mail.from.should eql([Site.current.smtp_sender]) }
            it("sets 'headers'") { mail.headers.should eql({}) }
            it("assigns @recording") { mail.body.encoded.should match(recording.room.name) }
            it { mail.body.encoded.should match(format_date(recording.created_at, :long)) }
            it { mail.body.encoded.should match(format_date(recording.expiration_date, :long, false)) }
          end
    
          context "for a room of a user" do
            let(:user) { FactoryGirl.create(:user) }
            before {
              room.update_attributes(owner: user)
              Rails.application.routes.url_helpers.should_not_receive(:my_recordings_url)
              CustomBigbluebuttonPlaybackTypesHelper.should_not_receive(:link_to_playback)
            }
    
            it("sets 'to'") { mail.to.should eql([user.email]) }
            it("sets 'subject'") {
              text = "[#{Site.current.name}] #{I18n.t('recording_mailer.recording_expiration.subject.expired', room: recording.room.name)}"
              mail.subject.should eql(text)
            }
            it("sets 'from'") { mail.from.should eql([Site.current.smtp_sender]) }
            it("sets 'headers'") { mail.headers.should eql({}) }
            it("assigns @recording") { mail.body.encoded.should match(recording.room.name) }
            it { mail.body.encoded.should match(format_date(recording.created_at, :long)) }
            it { mail.body.encoded.should match(format_date(recording.expiration_date, :long, false)) }
          end
        end
      end
    end
end
