# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Sort members', :js do
  include Spec::Support::Helpers::Features::MembersHelpers

  let(:owner)     { create(:user, name: 'John Doe') }
  let(:developer) { create(:user, name: 'Mary Jane', last_sign_in_at: 5.days.ago) }
  let(:group)     { create(:group) }

  before do
    create(:group_member, :owner, user: owner, group: group, created_at: 5.days.ago)
    create(:group_member, :developer, user: developer, group: group, created_at: 3.days.ago)

    sign_in(owner)
  end

  context 'when `group_members_filtered_search` feature flag is enabled' do
    def expect_sort_by(text, sort_direction)
      within('[data-testid="members-sort-dropdown"]') do
        expect(page).to have_css('button[aria-haspopup="true"]', text: text)
        expect(page).to have_button("Sorting Direction: #{sort_direction == :asc ? 'Ascending' : 'Descending'}")
      end
    end

    it 'sorts by account by default' do
      visit_members_list(sort: nil)

      expect(first_row.text).to include(owner.name)
      expect(second_row.text).to include(developer.name)

      expect_sort_by('Account', :asc)
    end

    it 'sorts by max role ascending' do
      visit_members_list(sort: :access_level_asc)

      expect(first_row.text).to include(developer.name)
      expect(second_row.text).to include(owner.name)

      expect_sort_by('Max role', :asc)
    end

    it 'sorts by max role descending' do
      visit_members_list(sort: :access_level_desc)

      expect(first_row.text).to include(owner.name)
      expect(second_row.text).to include(developer.name)

      expect_sort_by('Max role', :desc)
    end

    it 'sorts by access granted ascending' do
      visit_members_list(sort: :last_joined)

      expect(first_row.text).to include(developer.name)
      expect(second_row.text).to include(owner.name)

      expect_sort_by('Access granted', :asc)
    end

    it 'sorts by access granted descending' do
      visit_members_list(sort: :oldest_joined)

      expect(first_row.text).to include(owner.name)
      expect(second_row.text).to include(developer.name)

      expect_sort_by('Access granted', :desc)
    end

    it 'sorts by account ascending' do
      visit_members_list(sort: :name_asc)

      expect(first_row.text).to include(owner.name)
      expect(second_row.text).to include(developer.name)

      expect_sort_by('Account', :asc)
    end

    it 'sorts by account descending' do
      visit_members_list(sort: :name_desc)

      expect(first_row.text).to include(developer.name)
      expect(second_row.text).to include(owner.name)

      expect_sort_by('Account', :desc)
    end

    it 'sorts by last sign-in ascending', :clean_gitlab_redis_shared_state do
      visit_members_list(sort: :recent_sign_in)

      expect(first_row.text).to include(owner.name)
      expect(second_row.text).to include(developer.name)

      expect_sort_by('Last sign-in', :asc)
    end

    it 'sorts by last sign-in descending', :clean_gitlab_redis_shared_state do
      visit_members_list(sort: :oldest_sign_in)

      expect(first_row.text).to include(developer.name)
      expect(second_row.text).to include(owner.name)

      expect_sort_by('Last sign-in', :desc)
    end
  end

  context 'when `group_members_filtered_search` feature flag is disabled' do
    dropdown_toggle_selector = '[data-testid="user-sort-dropdown"] [data-testid="dropdown-toggle"]'

    before do
      stub_feature_flags(group_members_filtered_search: false)
    end

    it 'sorts alphabetically by default' do
      visit_members_list(sort: nil)

      expect(first_row.text).to include(owner.name)
      expect(second_row.text).to include(developer.name)
      expect(page).to have_css(dropdown_toggle_selector, text: 'Name, ascending')
    end

    it 'sorts by access level ascending' do
      visit_members_list(sort: :access_level_asc)

      expect(first_row.text).to include(developer.name)
      expect(second_row.text).to include(owner.name)
      expect(page).to have_css(dropdown_toggle_selector, text: 'Access level, ascending')
    end

    it 'sorts by access level descending' do
      visit_members_list(sort: :access_level_desc)

      expect(first_row.text).to include(owner.name)
      expect(second_row.text).to include(developer.name)
      expect(page).to have_css(dropdown_toggle_selector, text: 'Access level, descending')
    end

    it 'sorts by last joined' do
      visit_members_list(sort: :last_joined)

      expect(first_row.text).to include(developer.name)
      expect(second_row.text).to include(owner.name)
      expect(page).to have_css(dropdown_toggle_selector, text: 'Last joined')
    end

    it 'sorts by oldest joined' do
      visit_members_list(sort: :oldest_joined)

      expect(first_row.text).to include(owner.name)
      expect(second_row.text).to include(developer.name)
      expect(page).to have_css(dropdown_toggle_selector, text: 'Oldest joined')
    end

    it 'sorts by name ascending' do
      visit_members_list(sort: :name_asc)

      expect(first_row.text).to include(owner.name)
      expect(second_row.text).to include(developer.name)
      expect(page).to have_css(dropdown_toggle_selector, text: 'Name, ascending')
    end

    it 'sorts by name descending' do
      visit_members_list(sort: :name_desc)

      expect(first_row.text).to include(developer.name)
      expect(second_row.text).to include(owner.name)
      expect(page).to have_css(dropdown_toggle_selector, text: 'Name, descending')
    end

    it 'sorts by recent sign in', :clean_gitlab_redis_shared_state do
      visit_members_list(sort: :recent_sign_in)

      expect(first_row.text).to include(owner.name)
      expect(second_row.text).to include(developer.name)
      expect(page).to have_css(dropdown_toggle_selector, text: 'Recent sign in')
    end

    it 'sorts by oldest sign in', :clean_gitlab_redis_shared_state do
      visit_members_list(sort: :oldest_sign_in)

      expect(first_row.text).to include(developer.name)
      expect(second_row.text).to include(owner.name)
      expect(page).to have_css(dropdown_toggle_selector, text: 'Oldest sign in')
    end
  end

  def visit_members_list(sort:)
    visit group_group_members_path(group.to_param, sort: sort)
  end
end
