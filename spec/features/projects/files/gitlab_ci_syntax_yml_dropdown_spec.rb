# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User wants to add a .gitlab-ci.yml file' do
  before do
    project = create(:project, :repository)
    sign_in project.owner
    stub_experiment(ci_syntax_templates: experiment_active)
    stub_experiment_for_subject(ci_syntax_templates: in_experiment_group)

    visit project_new_blob_path(project, 'master', file_name: '.gitlab-ci.yml')
  end

  context 'when experiment is not active' do
    let(:experiment_active) { false }
    let(:in_experiment_group) { false }

    it 'does not show the "Learn CI/CD syntax" template dropdown' do
      expect(page).not_to have_css('.gitlab-ci-syntax-yml-selector')
    end
  end

  context 'when experiment is active and the user is in the control group' do
    let(:experiment_active) { true }
    let(:in_experiment_group) { false }

    it 'does not show the "Learn CI/CD syntax" template dropdown' do
      expect(page).not_to have_css('.gitlab-ci-syntax-yml-selector')
    end
  end

  context 'when experiment is active and the user is in the experimental group' do
    let(:experiment_active) { true }
    let(:in_experiment_group) { true }

    it 'allows the user to pick a "Learn CI/CD syntax" template from the dropdown', :js do
      expect(page).to have_css('.gitlab-ci-syntax-yml-selector')

      find('.js-gitlab-ci-syntax-yml-selector').click

      wait_for_requests

      within '.gitlab-ci-syntax-yml-selector' do
        find('.dropdown-input-field').set('Artifacts example')
        find('.dropdown-content .is-focused', text: 'Artifacts example').click
      end

      wait_for_requests

      expect(page).to have_css('.gitlab-ci-syntax-yml-selector .dropdown-toggle-text', text: 'Learn CI/CD syntax')
      expect(page).to have_content('You can use artifacts to pass data to jobs in later stages.')
    end
  end
end
