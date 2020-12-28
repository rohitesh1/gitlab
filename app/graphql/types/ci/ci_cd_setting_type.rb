# frozen_string_literal: true

module Types
  module Ci
    class CiCdSettingType < BaseObject
      graphql_name 'ProjectCiCdSetting'

      authorize :admin_project

      field :merge_pipelines_enabled, GraphQL::BOOLEAN_TYPE, null: true,
        description: 'Whether merge pipelines are enabled.',
        method: :merge_pipelines_enabled?
      field :merge_trains_enabled, GraphQL::BOOLEAN_TYPE, null: true,
        description:  'Whether merge trains are enabled.',
        method: :merge_trains_enabled?
      field :project, Types::ProjectType, null: true,
        description: 'Project the CI/CD settings belong to.'
    end
  end
end
