# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

# Finds all Invitation objects not sent yet and ready to be sent and schedules a
# worker to send them.
class UserNotificationsWorker
  @queue = :user_notifications

  def self.perform
    if Site.current.require_registration_approval
      notify_admins_of_new_users
      notify_users_after_approved
    end
  end

  # Finds all users that registered and need to be approved and schedules a worker
  # to notify all users that could possibly approve him.
  def self.notify_admins_of_new_users
    activities = RecentActivity.where(trackable_type: 'User', notified: [nil, false])
                               .where("`key` LIKE '%user.created'")
    recipients = User.where(superuser: true).pluck(:id)
    unless recipients.empty?
      activities.each do |creation|
        # If user created is a superuser we don't need to send the notification,
        # and mark it as sent so it doesn't come back to the worker in future queries.
        if User.find(creation.trackable_id).superuser
          creation.update_attribute(:notified, true)
        else
          Resque.enqueue(UserNeedsApprovalSenderWorker, creation.id, recipients)
        end
      end
    end
  end

  # Finds all users that were approved but not notified of it yet and schedules
  # a worker to notify them.
  def self.notify_users_after_approved
    activities = RecentActivity.where trackable_type: 'User', key: 'user.approved', notified: [nil, false]
    activities.each do |approval|
      Resque.enqueue(UserApprovedSenderWorker, approval.id)
    end
  end

end
