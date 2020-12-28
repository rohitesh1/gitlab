# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module MergeRequestActivityUniqueCounter
      MR_DIFFS_ACTION = 'i_code_review_mr_diffs'
      MR_DIFFS_SINGLE_FILE_ACTION = 'i_code_review_mr_single_file_diffs'
      MR_DIFFS_USER_SINGLE_FILE_ACTION = 'i_code_review_user_single_file_diffs'

      class << self
        def track_mr_diffs_action(merge_request:)
          track_unique_action_by_merge_request(MR_DIFFS_ACTION, merge_request)
        end

        def track_mr_diffs_single_file_action(merge_request:, user:)
          track_unique_action_by_merge_request(MR_DIFFS_SINGLE_FILE_ACTION, merge_request)
          track_unique_action_by_user(MR_DIFFS_USER_SINGLE_FILE_ACTION, user)
        end

        private

        def track_unique_action_by_merge_request(action, merge_request)
          track_unique_action(action, merge_request.id)
        end

        def track_unique_action_by_user(action, user)
          return unless user

          track_unique_action(action, user.id)
        end

        def track_unique_action(action, value)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_usage_event(action, value)
        end
      end
    end
  end
end
