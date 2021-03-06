<script>
import $ from 'jquery';
import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import LabelsSelect from '~/labels_select';
import DropdownHiddenInput from '~/vue_shared/components/dropdown/dropdown_hidden_input.vue';

import DropdownTitle from './dropdown_title.vue';
import DropdownValue from './dropdown_value.vue';
import DropdownValueCollapsed from './dropdown_value_collapsed.vue';
import DropdownButton from './dropdown_button.vue';
import DropdownHeader from './dropdown_header.vue';
import DropdownSearchInput from './dropdown_search_input.vue';
import DropdownFooter from './dropdown_footer.vue';
import DropdownCreateLabel from './dropdown_create_label.vue';

import { DropdownVariant } from '../labels_select_vue/constants';

export default {
  DropdownVariant,
  components: {
    DropdownTitle,
    DropdownValue,
    DropdownValueCollapsed,
    DropdownButton,
    DropdownHiddenInput,
    DropdownHeader,
    DropdownSearchInput,
    DropdownFooter,
    DropdownCreateLabel,
    GlLoadingIcon,
  },
  props: {
    showCreate: {
      type: Boolean,
      required: false,
      default: false,
    },
    isProject: {
      type: Boolean,
      required: false,
      default: false,
    },
    abilityName: {
      type: String,
      required: true,
    },
    context: {
      type: Object,
      required: true,
    },
    namespace: {
      type: String,
      required: false,
      default: '',
    },
    updatePath: {
      type: String,
      required: false,
      default: '',
    },
    labelsPath: {
      type: String,
      required: true,
    },
    labelsWebUrl: {
      type: String,
      required: false,
      default: '',
    },
    labelFilterBasePath: {
      type: String,
      required: false,
      default: '',
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    enableScopedLabels: {
      type: Boolean,
      required: false,
      default: false,
    },
    variant: {
      type: String,
      required: false,
      default: DropdownVariant.Sidebar,
    },
  },
  computed: {
    hiddenInputName() {
      return this.showCreate ? `${this.abilityName}[label_names][]` : 'label_id[]';
    },
    createLabelTitle() {
      if (this.isProject) {
        return __('Create project label');
      }

      return __('Create group label');
    },
    manageLabelsTitle() {
      if (this.isProject) {
        return __('Manage project labels');
      }

      return __('Manage group labels');
    },
  },
  mounted() {
    this.labelsDropdown = new LabelsSelect(this.$refs.dropdownButton, {
      handleClick: this.handleClick,
    });
    $(this.$refs.dropdown).on('hidden.gl.dropdown', this.handleDropdownHidden);
  },
  methods: {
    handleClick(label) {
      this.$emit('onLabelClick', label);
    },
    handleCollapsedValueClick() {
      this.$emit('toggleCollapse');
    },
    handleDropdownHidden() {
      this.$emit('onDropdownClose');
    },
  },
};
</script>

<template>
  <div class="block labels js-labels-block">
    <dropdown-value-collapsed
      v-if="showCreate && variant === $options.DropdownVariant.Sidebar"
      :labels="context.labels"
      @onValueClick="handleCollapsedValueClick"
    />
    <dropdown-title :can-edit="canEdit" />
    <dropdown-value
      :labels="context.labels"
      :label-filter-base-path="labelFilterBasePath"
      :enable-scoped-labels="enableScopedLabels"
    >
      <slot></slot>
    </dropdown-value>
    <div v-if="canEdit" class="selectbox js-selectbox" style="display: none">
      <dropdown-hidden-input
        v-for="label in context.labels"
        :key="label.id"
        :name="hiddenInputName"
        :value="label.id"
      />
      <div ref="dropdown" class="dropdown">
        <dropdown-button
          :ability-name="abilityName"
          :field-name="hiddenInputName"
          :update-path="updatePath"
          :labels-path="labelsPath"
          :namespace="namespace"
          :labels="context.labels"
          :show-extra-options="!showCreate || variant !== $options.DropdownVariant.Sidebar"
          :enable-scoped-labels="enableScopedLabels"
        />
        <div
          class="dropdown-menu dropdown-select dropdown-menu-paging dropdown-menu-labels dropdown-menu-selectable"
        >
          <div class="dropdown-page-one">
            <dropdown-header v-if="showCreate && variant === $options.DropdownVariant.Sidebar" />
            <dropdown-search-input />
            <div class="dropdown-content" data-qa-selector="labels_dropdown_content"></div>
            <div class="dropdown-loading">
              <gl-loading-icon
                class="gl-display-flex gl-justify-content-center gl-align-items-center gl-h-full"
              />
            </div>
            <dropdown-footer
              v-if="showCreate"
              :labels-web-url="labelsWebUrl"
              :create-label-title="createLabelTitle"
              :manage-labels-title="manageLabelsTitle"
            />
          </div>
          <dropdown-create-label
            v-if="showCreate"
            :is-project="isProject"
            :header-title="createLabelTitle"
          />
        </div>
      </div>
    </div>
  </div>
</template>
