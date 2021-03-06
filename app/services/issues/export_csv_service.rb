# frozen_string_literal: true

module Issues
  class ExportCsvService
    include Gitlab::Routing.url_helpers
    include GitlabRoutingHelper

    # Target attachment size before base64 encoding
    TARGET_FILESIZE = 15000000

    attr_reader :project

    def initialize(issues_relation, project)
      @issues = issues_relation
      @labels = @issues.labels_hash
      @project = project
    end

    def csv_data
      csv_builder.render(TARGET_FILESIZE)
    end

    def email(user)
      Notify.issues_csv_email(user, project, csv_data, csv_builder.status).deliver_now
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def csv_builder
      @csv_builder ||=
        CsvBuilder.new(@issues.preload(associations_to_preload), header_to_value_hash)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def associations_to_preload
      %i(author assignees timelogs milestone)
    end

    def header_to_value_hash
      {
       'Issue ID' => 'iid',
       'URL' => -> (issue) { issue_url(issue) },
       'Title' => 'title',
       'State' => -> (issue) { issue.closed? ? 'Closed' : 'Open' },
       'Description' => 'description',
       'Author' => 'author_name',
       'Author Username' => -> (issue) { issue.author&.username },
       'Assignee' => -> (issue) { issue.assignees.map(&:name).join(', ') },
       'Assignee Username' => -> (issue) { issue.assignees.map(&:username).join(', ') },
       'Confidential' => -> (issue) { issue.confidential? ? 'Yes' : 'No' },
       'Locked' => -> (issue) { issue.discussion_locked? ? 'Yes' : 'No' },
       'Due Date' => -> (issue) { issue.due_date&.to_s(:csv) },
       'Created At (UTC)' => -> (issue) { issue.created_at&.to_s(:csv) },
       'Updated At (UTC)' => -> (issue) { issue.updated_at&.to_s(:csv) },
       'Closed At (UTC)' => -> (issue) { issue.closed_at&.to_s(:csv) },
       'Milestone' => -> (issue) { issue.milestone&.title },
       'Weight' => -> (issue) { issue.weight },
       'Labels' => -> (issue) { issue_labels(issue) },
       'Time Estimate' => ->(issue) { issue.time_estimate.to_s(:csv) },
       'Time Spent' => -> (issue) { issue_time_spent(issue) }
      }
    end

    def issue_labels(issue)
      @labels[issue.id].sort.join(',').presence
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def issue_time_spent(issue)
      issue.timelogs.map(&:time_spent).sum
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end

Issues::ExportCsvService.prepend_if_ee('EE::Issues::ExportCsvService')
