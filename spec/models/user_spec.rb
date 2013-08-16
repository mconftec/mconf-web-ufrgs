# -*- coding: utf-8 -*-
require "spec_helper"

describe User do
  it "should automatically create the profile of a user after creating the user" do
    @user = Factory.create(:user)
    @user.profile.should_not be_nil
  end

  it "should automatically create the bbb room of a user after creating the user" do
    @user = Factory.create(:user)
    @user.bigbluebutton_room.should_not be_nil
  end

  describe "with valid attributes" do
    it "should create a new instance" do
      Factory.build(:user).should be_valid
    end

    it "should not create a new instance given no email" do
      User.create(:email => nil).should_not be_valid
    end
  end

  [ :receive_digest ].each do |attribute|
    it { should allow_mass_assignment_of(attribute) }
  end

  describe "login uses a unique permalink" do
    let(:user) { Factory.create(:user, :_full_name => "User Name", :login => nil) }
    let(:user2) { Factory.create(:user, :_full_name => user.full_name, :login => nil) }

    it { user.login.should eq("user-name") }
    it { user2.login.should eq("user-name-2") }

    describe "and cannot conflict with some space's permalink" do
      let(:space) { Factory.create(:space, :name => "User Name") }

      describe "when a user is created" do
        it { space.permalink.should eq("user-name") }
        it {
          space
          user
          user2
          user.login.should eq("user-name-2")
          user2.login.should eq("user-name-3")
        }
      end

      describe "when a user is updated" do
        let(:user3) { Factory.create(:user, :_full_name => "User Name New", :login => nil) }
        it { space.permalink.should eq("user-name") }
        it { user3.login.should eq("user-name-new") }
        it {
          space
          user3.update_attributes(:login => "user-name")
          user3.errors[:login].should include(I18n.t('activerecord.errors.messages.taken'))
        }
        it {
          user3.update_attributes(:login => "user-name-bbb")
          user3.bigbluebutton_room.param.should eq("user-name-bbb")
          user3.bigbluebutton_room.name.should eq("user-name-bbb")
        }
      end

      describe "#bigbluebutton room" do
        it { should have_one(:bigbluebutton_room).dependent(:destroy) }
        it { should accept_nested_attributes_for(:bigbluebutton_room) }
      end
    end

  end

  describe "#accessible_rooms" do
    let(:user) { Factory.create(:user) }
    let(:user_room) { Factory.create(:bigbluebutton_room, :owner => user) }
    let(:private_space_member) { Factory.create(:private_space) }
    let(:private_space_not_member) { Factory.create(:private_space) }
    let(:public_space_member) { Factory.create(:public_space) }
    let(:public_space_not_member) { Factory.create(:public_space) }
    before do
      user_room
      public_space_not_member
      Factory.create(:user_performance, :agent => user, :stage => private_space_member)
      Factory.create(:user_performance, :agent => user, :stage => public_space_member)
    end

    subject { user.accessible_rooms }
    # it { subject.count.should == 4 }
    it { subject.should == subject.uniq }
    it { should include(user_room) }
    it { should include(private_space_member.bigbluebutton_room) }
    it { should include(public_space_member.bigbluebutton_room) }
    it { should include(public_space_not_member.bigbluebutton_room) }
    it { should_not include(private_space_not_member.bigbluebutton_room) }
  end

  describe "#can_record_meeting?" do

    context "for a superuser" do
      let(:user) { Factory.create(:superuser) }

      it "can record when the room is not informed" do
        user.can_record_meeting?.should be_true
      end

      it "can record in his room" do
        user.can_record_meeting?(user.bigbluebutton_room).should be_true
      end

      it "can record in another user's room" do
        another = Factory.create(:user)
        user.can_record_meeting?(another.bigbluebutton_room).should be_true
      end

      it "can record in a room of a space he belongs to" do
        space = Factory.create(:space)
        Factory(:user_performance, :stage => space, :agent => user)
        user.can_record_meeting?(space.bigbluebutton_room).should be_true
      end

      it "can record in a room of a space he does not belongs to" do
        space = Factory.create(:space)
        user.can_record_meeting?(space.bigbluebutton_room).should be_true
      end
    end

    context "for a normal user" do
      let(:user) { Factory.create(:user) }
      # cannot record, ever, because he has no enrollment set
      before { user.shib_token = nil }
      it { user.can_record_meeting?.should be_false }
      it { user.can_record_meeting?(user.bigbluebutton_room).should be_false }
    end

    # users with a valid #shib_token
    context "for a normal user logged via federation" do
      let(:user) { Factory.create(:user) }

      context "without the shib variable 'ufrgsVinculo'" do
        let(:token) {
          t = Factory.create(:shib_token, :user => user)
          t.data = t.data_as_hash.except!("ufrgsVinculo").to_yaml
          t
        }
        before { user.update_attribute("shib_token", token) }
        it { user.can_record_meeting?.should be_false }
        it { user.can_record_meeting?(user.bigbluebutton_room).should be_false }
      end

      context "without an active enrollment" do
        let(:token) { Factory.create(:shib_token, :user => user) }
        it { user.can_record_meeting?.should be_false }
        it { user.can_record_meeting?(user.bigbluebutton_room).should be_false }
      end

      context "with an active enrollment" do
        context "but with a role that can't record" do
          let(:token) { Factory.create(:shib_token, :user => user) }
          before {
            data = token.data_as_hash
            data["ufrgsVinculo"] = "ativo:12:Aluno de doutorado:1:Instituto de Informática:NULL:NULL:NULL:NULL:01/01/2011:NULL"
            token.update_attribute("data", data.to_yaml)
          }
          it { user.can_record_meeting?.should be_false }
          it { user.can_record_meeting?(user.bigbluebutton_room).should be_false }
        end

        ["Docente", "Técnico-Administrativo", "Funcionário de Fundações da UFRGS",
         "Tutor de disciplina", "Professor visitante", "Colaborador convidado"].each do |enrollment|

          context "as '#{enrollment}'" do
            let(:token) { Factory.create(:shib_token, :user => user) }
            before {
              data = token.data_as_hash
              data["ufrgsVinculo"] = "ativo:2:#{enrollment}:1:Instituto de Informática:NULL:NULL:NULL:NULL:01/01/2011:NULL"
              token.update_attribute("data", data.to_yaml)
            }

            it "can record when the room is not informed" do
              user.can_record_meeting?.should be_true
            end

            it "can record in his room" do
              user.can_record_meeting?(user.bigbluebutton_room).should be_true
            end

            it "cannot record in another user's room" do
              another = Factory.create(:user)
              user.can_record_meeting?(another.bigbluebutton_room).should be_false
            end

            it "can record in a room of a space he belongs to" do
              space = Factory.create(:space)
              Factory(:user_performance, :stage => space, :agent => user)
              user.can_record_meeting?(space.bigbluebutton_room).should be_true
            end

            it "cannot record in a room of a space he does not belongs to" do
              space = Factory.create(:space)
              user.can_record_meeting?(space.bigbluebutton_room).should be_false
            end
          end

        end

        context "ignores accents when matching the enrollment" do
          let(:token) { Factory.create(:shib_token, :user => user) }
          before {
            data = token.data_as_hash
            data["ufrgsVinculo"] = "ativo:12:Funcionario de Fundacoes da UFRGS:1:Instituto de Informática:NULL:NULL:NULL:NULL:01/01/2011:NULL"
            token.update_attribute("data", data.to_yaml)
          }
          it { user.can_record_meeting?.should be_true }
        end

        context "with more than one active enrollment" do
          context "and one allows recording" do
            let(:token) { Factory.create(:shib_token, :user => user) }
            before {
              data = token.data_as_hash
              data["ufrgsVinculo"] = "ativo:11:Docente:1:Instituto de Informática:NULL:NULL:NULL:NULL:01/01/2011:NULL;ativo:6:Aluno de mestrado acadêmico:NULL:NULL:NULL:NULL:2:COMPUTAÇÃO:01/01/2001:11/12/2002"
              token.update_attribute("data", data.to_yaml)
            }
            it { user.can_record_meeting?.should be_true }
          end

          context "but none allows recording" do
            let(:token) { Factory.create(:shib_token, :user => user) }
            before {
              data = token.data_as_hash
              data["ufrgsVinculo"] = "ativo:11:Aluno de doutorado:1:Instituto de Informática:NULL:NULL:NULL:NULL:01/01/2011:NULL;ativo:6:Aluno de mestrado acadêmico:NULL:NULL:NULL:NULL:2:COMPUTAÇÃO:01/01/2001:11/12/2002"
              token.update_attribute("data", data.to_yaml)
            }
            it { user.can_record_meeting?.should be_false }
          end
        end

      end
    end

  end

  describe "#is_moderator?" do
    let(:user) { Factory.create(:user) }

    it "false if the room is not informed" do
      user.is_moderator?.should be_false
    end

    it "true for his room" do
      user.is_moderator?(user.bigbluebutton_room).should be_true
    end

    it "false for another user's room" do
      another = Factory.create(:user)
      user.is_moderator?(another.bigbluebutton_room).should be_false
    end

    it "false for a room of a space he belongs to" do
      space = Factory.create(:space)
      Factory(:user_performance, :stage => space, :agent => user)
      user.is_moderator?(space.bigbluebutton_room).should be_true
    end

    it "false for a room of a space he does not belongs to" do
      space = Factory.create(:space)
      user.is_moderator?(space.bigbluebutton_room).should be_false
    end
  end

end
