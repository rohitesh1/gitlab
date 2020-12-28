# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Query.project.pipeline.stages.groups' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository, :public) }
  let(:user) { create(:user) }
  let(:pipeline) { create(:ci_pipeline, project: project, user: user) }
  let(:group_graphql_data) { graphql_data.dig('project', 'pipeline', 'stages', 'nodes', 0, 'groups', 'nodes') }

  let(:params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('CiGroup')}
      }
    QUERY
  end

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          pipeline(iid: "#{pipeline.iid}") {
            stages {
              nodes {
                groups {
                  #{fields}
                }
              }
            }
          }
        }
      }
    )
  end

  before do
    create(:commit_status, pipeline: pipeline, name: 'rspec 0 2')
    create(:commit_status, pipeline: pipeline, name: 'rspec 0 1')
    create(:commit_status, pipeline: pipeline, name: 'spinach 0 1')
    post_graphql(query, current_user: user)
  end

  it_behaves_like 'a working graphql query'

  it 'returns a array of jobs belonging to a pipeline' do
    expect(group_graphql_data.map { |g| g.slice('name', 'size') }).to eq([
      { 'name' => 'rspec', 'size' => 2 },
      { 'name' => 'spinach', 'size' => 1 }
    ])
  end
end
