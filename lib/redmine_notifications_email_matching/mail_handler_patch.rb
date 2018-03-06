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

      ok_subject = cleaned_up_subject
      if ok_subject =~ OK_SUBJECT_REGEXP

        #
        # At times, the OK subject might differ from the PROBLEM one
        # if they include the actual problematic value, e.g. number of
        # seconds a longest-running DB query was idle.  The exact
        # matching is not possible in such case.
        #
        # We replace any numbers found in the subject with the
        # substring placeholder for smart-matching.  To avoid matching
        # numbers that are valid substrings in names like 'apache2' we
        # requre a leading whitespace before the number.  To properly
        # match strings like '123s' (for 'seconds') we don't require
        # the trailing space.
        #
        problem_pattern = ok_subject.sub('OK', 'PROBLEM').gsub(/\s\d+(\.\d+)?/, ' %')
        problem_scope = target_project.issues.open.order(:created_on).where(["#{Issue.table_name}.subject LIKE ?", problem_pattern])

        if problem_issue = problem_scope.last
          begin
            instance_variable_set("@matched_subject_from_email", true)

            # update subject silently
            problem_issue.subject = ok_subject
            problem_issue.save

            return receive_issue_reply(problem_issue.id)
            # ^^^^ so that we don't fall through to unpatched logic
          ensure
            instance_variable_set("@matched_subject_from_email", false)
          end
        end
      end

      receive_issue_without_notifications_email_matching
    end

    def issue_attributes_from_keywords_with_notifications_email_matching(issue)
      issue_attributes_from_keywords_without_notifications_email_matching(issue).tap do |attrs|
        if instance_variable_get("@matched_subject_from_email")
          # only close issue if there were no updates to it and it is a fresh ticket
          if issue.journals.size == 0 and (Time.now - issue.created_on) < 15.minutes
            if status_to_close = issue.new_statuses_allowed_to.detect(&:is_closed?)
              issue.status = status_to_close
            end
          end
        end
      end
    end
  end
end
