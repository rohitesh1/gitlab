# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Seed < Chain::Base
          include Chain::Helpers
          include Gitlab::Utils::StrongMemoize

          def perform!
            raise ArgumentError, 'missing YAML processor result' unless @command.yaml_processor_result

            # Allocate next IID. This operation must be outside of transactions of pipeline creations.
            pipeline.ensure_project_iid!
            pipeline.ensure_ci_ref!

            # Protect the pipeline. This is assigned in Populate instead of
            # Build to prevent erroring out on ambiguous refs.
            pipeline.protected = @command.protected_ref?

            unless ::Gitlab::Ci::Features.seed_block_run_before_workflow_rules_enabled?(project)
              ##
              # Populate pipeline with block argument of CreatePipelineService#execute.
              #
              @command.seeds_block&.call(pipeline)
            end

            ##
            # Gather all runtime build/stage errors
            #
            if pipeline_seed.errors
              return error(pipeline_seed.errors.join("\n"), config_error: true)
            end

            @command.pipeline_seed = pipeline_seed
          end

          def break?
            pipeline.errors.any?
          end

          private

          def pipeline_seed
            strong_memoize(:pipeline_seed) do
              stages_attributes = @command.yaml_processor_result.stages_attributes
              Gitlab::Ci::Pipeline::Seed::Pipeline.new(pipeline, stages_attributes)
            end
          end
        end
      end
    end
  end
end
