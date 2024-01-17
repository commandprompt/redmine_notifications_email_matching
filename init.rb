require 'redmine'

Redmine::Plugin.register :redmine_notifications_email_matching do
  name 'Redmine Notifications Email Matching plugin'
  author 'Alex Shulgin <ash@commandprompt.com>'
  description 'A plugin to match Zabbix-style PROBLEM/OK email notifications to route OK as the update to the PROBLEM ticket.'
  version '0.2.3'
  requires_redmine :version_or_higher => '5.0'
  url 'http://github.com/commandprompt/redmine_notifications_email_matching'
end

MailHandler.send(:include, RedmineNotificationsEmailMatching::MailHandlerPatch)

