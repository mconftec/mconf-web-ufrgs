# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require "spec_helper"

describe BigbluebuttonRecording do

  describe "from initializers/bigbluebutton_rails" do
    it("should have a method .search_by_terms") {
      BigbluebuttonRecording.should respond_to(:search_by_terms)
    }

    describe ".search_by_terms" do
      it "includes the associated room"
      it "searches by name"
      it "searches by description"
      it "searches by room name"
      it "searches by recordid"
      it "searches by all attributes together"
      it "searches with multiple words"
    end

    it("should have a method .has_playback") {
      BigbluebuttonRecording.should respond_to(:has_playback)
    }

    describe ".has_playback" do
      it "filters the query to return only recordings with at least one playback"
    end

    it("should have a method .no_playback") {
      BigbluebuttonRecording.should respond_to(:no_playback)
    }

    describe ".no_playback" do
      it "filters the query to return only recordings with no playback"
    end

    describe "#new_activity_recording_expiration" do
      let(:user) { FactoryGirl.create(:user) }
      let(:target) { FactoryGirl.create(:bigbluebutton_recording) }
      let(:params) {
        { expires_in: 10, owners: [{ id: user.id, username: user.username }] }
      }

      context "if there's no activity of this type yet" do
        before {
          with_activities do
            target.stub(:expires_in_slot).and_return(10)
            target.stub(:owners).and_return([user])
            expect { target.new_activity_recording_expiration }.to change{RecentActivity.count}.by(1)
          end
        }
        it { RecentActivity.last.key.should eql('bigbluebutton_recording.expiration_10') }
        it { RecentActivity.last.owner.should eql(target) }
        it { RecentActivity.last.trackable.should eql(target) }
        it { RecentActivity.last.recipient.should be_nil }
        it { RecentActivity.last.parameters.should eql(params) }
      end

      context "if there's already an activity" do
        before {
          target.stub(:expires_in_slot).and_return(10)
          target.stub(:owners).and_return([user])
          RecentActivity.create(key: 'bigbluebutton_recording.expiration_10', trackable: target)
        }
        it {
          with_activities do
            expect { target.new_activity_recording_expiration }.not_to change{RecentActivity.count}
          end
        }
      end
    end

    describe "#owners" do
      let(:target) { FactoryGirl.create(:bigbluebutton_recording) }

      context "if the recording belongs to a user" do
        let(:user) { FactoryGirl.create(:user) }
        before {
          target.room.update_attributes(owner: user)
        }

        context "without #recording_users" do
          it { target.owners.should eql([user]) }
        end

        context "with #recording_users" do
          let!(:user2) { FactoryGirl.create(:user) }
          let!(:user3) { FactoryGirl.create(:user) }
          before {
            target.update_attributes(recording_users: [user2.id, user3.id, user.id])
          }
          it { target.owners.size.should eql(3) } # no duplicates
          it { target.owners.should eql([user, user2, user3]) }
        end
      end

      context "if the recording belongs to a space" do
        let(:space) { FactoryGirl.create(:space) }
        let(:admin) { FactoryGirl.create(:user) }
        let(:member) { FactoryGirl.create(:user) }
        before {
          target.room.update_attributes(owner: space)
          space.add_member!(admin, 'Admin')
          space.add_member!(member, 'User')
        }

        context "without #recording_users" do
          it { target.owners.size.should eql(1) }
          it { target.owners.should include(admin) }
        end

        context "with #recording_users" do
          let!(:user2) { FactoryGirl.create(:user) }
          let!(:user3) { FactoryGirl.create(:user) }
          before {
            target.update_attributes(recording_users: [user2.id, user3.id, admin.id])
          }
          it { target.owners.size.should eql(3) } # no duplicates
          it { target.owners.should include(admin) }
          it { target.owners.should include(user2) }
          it { target.owners.should include(user3) }
        end
      end
    end

    describe "#expired?" do
      let(:target) { FactoryGirl.create(:bigbluebutton_recording) }
      let(:now) { DateTime.now }

      before {
        @previous = Rails.application.config.recordings_expiration_enabled
        Timecop.freeze(now)
      }
      after {
        Rails.application.config.recordings_expiration_enabled = @previous
      }

      context "when expiration is enabled" do
        before {
          Rails.application.config.recordings_expiration_enabled = true
        }
        it {
          target.stub(:expiration_date).and_return(now + 1.month)
          target.expired?.should be(false)
        }
        it {
          target.stub(:expiration_date).and_return(now + 1.second)
          target.expired?.should be(false)
        }
        it {
          target.stub(:expiration_date).and_return(now)
          target.expired?.should be(true)
        }
        it {
          target.stub(:expiration_date).and_return(now - 1.second)
          target.expired?.should be(true)
        }
        it {
          target.stub(:expiration_date).and_return(now - 1.month)
          target.expired?.should be(true)
        }
      end

      context "when expiration is disabled" do
        before {
          Rails.application.config.recordings_expiration_enabled = false
        }
        it {
          target.stub(:expiration_date).and_return(now + 1.month)
          target.expired?.should be(false)
        }
        it {
          target.stub(:expiration_date).and_return(now - 1.month)
          target.expired?.should be(false)
        }
      end
    end

    describe "#expiring?" do
      let(:target) { FactoryGirl.create(:bigbluebutton_recording) }
      let(:now) { DateTime.now }
      before {
        Timecop.freeze(now)
      }

      before {
        Timecop.freeze(now)
        @warnings = Rails.application.config.recordings_expiration_warnings
        @expiration = Rails.application.config.recordings_expiration_enabled
        Rails.application.config.recordings_expiration_warnings = [10, 5, 1]
      }
      after {
        Rails.application.config.recordings_expiration_warnings = @warnings
        Rails.application.config.recordings_expiration_enabled = @expiration
      }

      context "when expiration is enabled" do
        before {
          Rails.application.config.recordings_expiration_enabled = true
        }
        it {
          target.stub(:expiration_date).and_return(now + 10.days + 1.second)
          target.expiring?.should be(false)
        }
        it {
          target.stub(:expiration_date).and_return(now + 10.days)
          target.expiring?.should be(true)
        }
        it {
          target.stub(:expiration_date).and_return(now + 5.days)
          target.expiring?.should be(true)
        }
        it {
          target.stub(:expiration_date).and_return(now + 1.days)
          target.expiring?.should be(true)
        }
        it {
          target.stub(:expiration_date).and_return(now - 1.days)
          target.expiring?.should be(true)
        }
      end

      context "when expiration is disabled" do
        before {
          Rails.application.config.recordings_expiration_enabled = false
        }
        it {
          target.stub(:expiration_date).and_return(now + 10.days)
          target.expiring?.should be(false)
        }
        it {
          target.stub(:expiration_date).and_return(now - 1.days)
          target.expiring?.should be(false)
        }
      end
    end

    describe "#expires_in_slot" do
      let(:target) { FactoryGirl.create(:bigbluebutton_recording) }
      let(:now) { DateTime.now }

      before {
        Timecop.freeze(now)
        @warnings = Rails.application.config.recordings_expiration_warnings
        @expiration = Rails.application.config.recordings_expiration_enabled
        Rails.application.config.recordings_expiration_warnings = [10, 5, 1]
      }
      after {
        Rails.application.config.recordings_expiration_warnings = @warnings
        Rails.application.config.recordings_expiration_enabled = @expiration
      }

      context "when expiration is enabled" do
        before {
          Rails.application.config.recordings_expiration_enabled = true
        }
        it {
          target.stub(:expiration_date).and_return(now + 10.days + 1.second)
          target.expires_in_slot.should be_nil
        }
        it {
          target.stub(:expiration_date).and_return(now + 10.days)
          target.expires_in_slot.should eql(10)
        }
        it {
          target.stub(:expiration_date).and_return(now + 5.days + 1.second)
          target.expires_in_slot.should eql(10)
        }
        it {
          target.stub(:expiration_date).and_return(now + 5.days)
          target.expires_in_slot.should eql(5)
        }
        it {
          target.stub(:expiration_date).and_return(now + 1.days + 1.second)
          target.expires_in_slot.should eql(5)
        }
        it {
          target.stub(:expiration_date).and_return(now + 1.days)
          target.expires_in_slot.should eql(1)
        }
        it {
          target.stub(:expiration_date).and_return(now + 1.hour)
          target.expires_in_slot.should eql(1)
        }
        it {
          target.stub(:expiration_date).and_return(now)
          target.expires_in_slot.should eql(0)
        }
        it {
          target.stub(:expiration_date).and_return(now - 1.day)
          target.expires_in_slot.should eql(0)
        }
      end

      context "when expiration is disabled" do
        before {
          Rails.application.config.recordings_expiration_enabled = false
        }
        it {
          target.stub(:expiration_date).and_return(now + 10.days + 1.second)
          target.expires_in_slot.should be_nil
        }
        it {
          target.stub(:expiration_date).and_return(now - 1.day)
          target.expires_in_slot.should be_nil
        }
      end
    end

    describe "#expiration_date" do
      let(:date) { DateTime.now }
      let(:target) { FactoryGirl.create(:bigbluebutton_recording, created_at: date, updated_at: date + 1.month) }
      let(:expected) { (date + Rails.application.config.recordings_expiration_months.months).utc }

      before {
        @expiration = Rails.application.config.recordings_expiration_enabled
      }
      after {
        Rails.application.config.recordings_expiration_enabled = @expiration
      }

      context "when expiration is enabled" do
        before {
          Rails.application.config.recordings_expiration_enabled = true
        }
        it { target.reload.expiration_date.utc.to_i.should eq(expected.to_i) }
        it { target.reload.expiration_date.utc?.should be(true) }
        it { target.reload.expiration_date.should be_a(DateTime) }
      end

      context "when expiration is disabled" do
        before {
          Rails.application.config.recordings_expiration_enabled = false
        }
        it { target.reload.expiration_date.should be_nil }
      end
    end
  end
  # This is a model from BigbluebuttonRails, but we have permissions set in cancan for it,
  # so we test them here.
  describe "abilities", :abilities => true do
    set_custom_ability_actions([:play, :user_show, :user_edit, :space_show, :space_edit])

    subject { ability }
    let(:user) { nil }
    let(:ability) { Abilities.ability_for(user) }

    context "a superuser for a recording", :user => "superuser" do
      let(:user) { FactoryGirl.create(:superuser) }

      context "in his own room" do
        let(:target) { FactoryGirl.create(:bigbluebutton_recording, :room => user.bigbluebutton_room) }
        it { should be_able_to_do_everything_to(target) }
      end

      context "in another user's room" do
        let(:another_user) { FactoryGirl.create(:user) }
        let(:target) { FactoryGirl.create(:bigbluebutton_recording, :room => another_user.bigbluebutton_room) }
        it { should be_able_to_do_everything_to(target) }
      end

      context "in a public space" do
        let(:space) { FactoryGirl.create(:space, :public => true) }
        let(:target) { FactoryGirl.create(:bigbluebutton_recording, :room => space.bigbluebutton_room) }

        context "he doesn't belong to" do
          it { should be_able_to_do_everything_to(target) }
        end

        context "he belongs to" do
          before { space.add_member!(user) }
          it { should be_able_to_do_everything_to(target) }
        end
      end

      context "in a private space" do
        let(:space) { FactoryGirl.create(:space_with_associations, public: false) }
        let(:target) { FactoryGirl.create(:bigbluebutton_recording, :room => space.bigbluebutton_room) }

        context "he doesn't belong to" do
          it { should be_able_to_do_everything_to(target) }
        end

        context "he belongs to" do
          before { space.add_member!(user) }
          it { should be_able_to_do_everything_to(target) }
        end
      end
    end

    context "a normal user for a recording", :user => "normal" do
      let(:user) { FactoryGirl.create(:user) }

      context "in his own room" do
        let(:target) { FactoryGirl.create(:bigbluebutton_recording, :room => user.bigbluebutton_room) }
        let(:allowed) { [:play, :update, :user_show, :user_edit] }
        it { should_not be_able_to_do_anything_to(target).except(allowed) }
      end

      context "in another user's room" do
        let(:another_user) { FactoryGirl.create(:user) }
        let(:target) { FactoryGirl.create(:bigbluebutton_recording, :room => another_user.bigbluebutton_room) }
        it { should_not be_able_to_do_anything_to(target) }
      end

      context "in a public space" do
        let(:space) { FactoryGirl.create(:space_with_associations, public: true) }
        let(:target) { FactoryGirl.create(:bigbluebutton_recording, :room => space.bigbluebutton_room) }

        context "he doesn't belong to" do
          let(:allowed) { [:play, :space_show] }
          it { should_not be_able_to_do_anything_to(target).except(allowed) }
        end

        context "he belongs to" do
          context "as a normal user" do
            before { space.add_member!(user) }
            let(:allowed) { [:play, :space_show] }
            it { should_not be_able_to_do_anything_to(target).except(allowed) }
          end

          context "as an admin" do
            before { space.add_member!(user, 'Admin') }
            let(:allowed) { [:play, :space_show, :update, :space_edit] }
            it { should_not be_able_to_do_anything_to(target).except(allowed) }
          end
        end
      end

      context "in a private space" do
        let(:space) { FactoryGirl.create(:space_with_associations, public: false) }
        let(:target) { FactoryGirl.create(:bigbluebutton_recording, :room => space.bigbluebutton_room) }

        context "he doesn't belong to" do
          it { should_not be_able_to_do_anything_to(target) }
        end

        context "he belongs to" do
          context "as a normal user" do
            before { space.add_member!(user) }
            let(:allowed) { [:play, :space_show] }
            it { should_not be_able_to_do_anything_to(target).except(allowed) }
          end

          context "as an admin" do
            before { space.add_member!(user, 'Admin') }
            let(:allowed) { [:play, :space_show, :update, :space_edit] }
            it { should_not be_able_to_do_anything_to(target).except(allowed) }
          end
        end
      end
    end

    context "an anonymous user for a recording", :user => "anonymous" do
      context "in a user's room" do
        let(:room) { FactoryGirl.create(:bigbluebutton_room, owner: FactoryGirl.create(:user)) }
        let(:target) { FactoryGirl.create(:bigbluebutton_recording, :room => room) }
        it { should_not be_able_to_do_anything_to(target) }
      end

      context "in a public space" do
        let(:space) { FactoryGirl.create(:space_with_associations, public: true) }
        let(:target) { FactoryGirl.create(:bigbluebutton_recording, :room => space.bigbluebutton_room) }
        let(:allowed) { [:play, :space_show] }
        it { should_not be_able_to_do_anything_to(target).except(allowed) }
      end

      context "in a private space" do
        let(:space) { FactoryGirl.create(:space_with_associations, public: false) }
        let(:target) { FactoryGirl.create(:bigbluebutton_recording, :room => space.bigbluebutton_room) }
        it { should_not be_able_to_do_anything_to(target) }
      end
    end

  end
end
