module RedmineNotificationsEmailMatching
  module MailHandlerPatch
    unloadable

    def self.included(base)
      base.class_eval do
        alias_method_chain :receive_issue, :notifications_email_matching
        alias_method_chain :issue_attributes_from_keywords, :notifications_email_matching
      end
    end

    OK_SUBJECT_REGEXP = /^.*OK: .*$/

    def receive_issue_with_notifications_email_matching
      instance_variable_set("@matched_subject_from_email", false)

      subject = cleaned_up_subject
      if subject =~ OK_SUBJECT_REGEXP and
          (issue = target_project.issues.open.order(:created_on).reverse_order.find_by_subject(subject.sub('OK', 'PROBLEM')))
        begin
          instance_variable_set("@matched_subject_from_email", true)

          # update subject silently
          issue.subject = subject
          issue.save

          receive_issue_reply(issue.id)
        ensure
          instance_variable_set("@matched_subject_from_email", false)
        end
      else
        receive_issue_without_notifications_email_matching
      end
    end

    def issue_attributes_from_keywords_with_notifications_email_matching(issue)
      issue_attributes_from_keywords_without_notifications_email_matching(issue).tap do |attrs|
        if instance_variable_get("@matched_subject_from_email")
          # only close issue if there were no updates to it and it is a fresh ticket
          if issue.journals.size == 0 and (Time.now - issue.created_on) < 15.minutes
            if status_to_close = issue.allowed_status_to_close
              attrs['status_id'] = status_to_close.id
            end
          end
        end
      end
    end
  end
end
