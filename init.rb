require 'redmine'

Redmine::Plugin.register :redmine_notifications_email_matching do
  name 'Redmine Notifications Email Matching plugin'
  author 'Alex Shulgin <ash@commandprompt.com>'
  description 'A plugin to match Zabbix-style PROBLEM/OK email notifications to route OK as the update to the PROBLEM ticket.'
  version '0.2.0'
  url 'http://github.com/commandprompt/redmine_notifications_email_matching'
  #  author_url 'http://example.com/about'

#  settings :default => {},
#    :partial => 'settings/redmine_notifications_email_matching'
end

prepare_block = Proc.new do
  MailHandler.send(:include, RedmineNotificationsEmailMatching::MailHandlerPatch)
end

if Rails.env.development?
  ActionDispatch::Reloader.to_prepare { prepare_block.call }
else
  prepare_block.call
end
