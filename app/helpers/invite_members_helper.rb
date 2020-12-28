# frozen_string_literal: true

module InviteMembersHelper
  include Gitlab::Utils::StrongMemoize

  def invite_members_allowed?(group)
    Feature.enabled?(:invite_members_group_modal, group) && can?(current_user, :admin_group_member, group)
  end

  def directly_invite_members?
    strong_memoize(:directly_invite_members) do
      experiment_enabled?(:invite_members_version_a) && can_import_members?
    end
  end

  def indirectly_invite_members?
    strong_memoize(:indirectly_invite_members) do
      experiment_enabled?(:invite_members_version_b) && !can_import_members?
    end
  end

  def invite_group_members?(group)
    experiment_enabled?(:invite_members_empty_group_version_a) && Ability.allowed?(current_user, :admin_group_member, group)
  end

  def dropdown_invite_members_link(form_model)
    link_to invite_members_url(form_model),
            data: {
              'track-event': 'click_link',
              'track-label': tracking_label(current_user),
              'track-property': experiment_tracking_category_and_group(:invite_members_new_dropdown, subject: current_user)
            } do
      invite_member_link_content
    end
  end

  private

  def invite_members_url(form_model)
    case form_model
    when Project
      project_project_members_path(form_model)
    when Group
      group_group_members_path(form_model)
    end
  end

  def invite_member_link_content
    text = s_('InviteMember|Invite members')

    return text unless experiment_enabled?(:invite_members_new_dropdown)

    "#{text} #{emoji_icon('shaking_hands', 'aria-hidden': true, class: 'gl-font-base gl-vertical-align-baseline')}".html_safe
  end
end
