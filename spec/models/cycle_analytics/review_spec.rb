# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CycleAnalytics#review' do
  extend CycleAnalyticsHelpers::TestGeneration

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:from_date) { 10.days.ago }
  let_it_be(:user) { project.owner }

  subject { CycleAnalytics::ProjectLevel.new(project, options: { from: from_date, current_user: user }) }

  generate_cycle_analytics_spec(
    phase: :review,
    data_fn: -> (context) { { issue: context.create(:issue, project: context.project) } },
    start_time_conditions: [["merge request that closes issue is created",
                             -> (context, data) do
                               context.create_merge_request_closing_issue(context.user, context.project, data[:issue])
                             end]],
    end_time_conditions:   [["merge request that closes issue is merged",
                             -> (context, data) do
                               context.merge_merge_requests_closing_issue(context.user, context.project, data[:issue])
                             end]],
    post_fn: nil)

  context "when a regular merge request (that doesn't close the issue) is created and merged" do
    it "returns nil" do
      MergeRequests::MergeService.new(project, user).execute(create(:merge_request))

      expect(subject[:review].project_median).to be_nil
    end
  end
end
