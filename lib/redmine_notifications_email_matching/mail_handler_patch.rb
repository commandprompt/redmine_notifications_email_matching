module RedmineNotificationsEmailMatching
  module MailHandlerPatch
    unloadable

    def self.included(base)
      base.class_eval do
        alias_method_chain :receive_issue, :notifications_email_matching
      end
    end

    OK_SUBJECT_REGEXP = /.*OK: .*/

    def receive_issue_with_notifications_email_matching
      subject = cleaned_up_subject
      if subject =~ OK_SUBJECT_REGEXP and
          (issue = target_project.issues.open.order(:created_on).reverse_order.find_by_subject(subject.sub('OK', 'PROBLEM')))
        receive_issue_reply(issue.id)
      else
        receive_issue_without_notifications_email_matching
      end
    end
  end
end
