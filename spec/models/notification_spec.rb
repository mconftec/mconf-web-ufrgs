# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require 'spec_helper'

describe Notification, type :model do
    include Rails.application.routes.url_helpers

    describe '#notify!' do
        context 'notify the actual notification' do
            let(:user) { FactoryGirl.create(:user) }
            let(:activity) { FactoryGirl.create(:recent_activity) }
            let(:notification) { FactoryGirl.create(:notification, user_id: user.ide, recent_activity: activity.id) }
            before {notification.notify! }
            it ('notification should be notified') { notification.reload.notified.should eql(true) }
        end
    end
