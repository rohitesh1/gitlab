# frozen_string_literal: true

module Namespaces
  class OnboardingPipelineCreatedWorker
    include ApplicationWorker

    feature_category :subgroups
    urgency :low

    deduplicate :until_executing
    idempotent!

    def perform(namespace_id)
      namespace = Namespace.find_by_id(namespace_id)
      return unless namespace

      OnboardingProgressService.new(namespace).execute(action: :pipeline_created)
    end
  end
end
