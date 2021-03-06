<script>
import {
  GlDropdown,
  GlDropdownDivider,
  GlDropdownItem,
  GlFormGroup,
  GlFormInput,
  GlIcon,
  GlModal,
  GlSprintf,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import lockState from '../graphql/mutations/lock_state.mutation.graphql';
import unlockState from '../graphql/mutations/unlock_state.mutation.graphql';
import removeState from '../graphql/mutations/remove_state.mutation.graphql';

export default {
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    GlFormGroup,
    GlFormInput,
    GlIcon,
    GlModal,
    GlSprintf,
  },
  props: {
    state: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      loading: false,
      showRemoveModal: false,
      removeConfirmText: '',
    };
  },
  i18n: {
    downloadJSON: s__('Terraform|Download JSON'),
    lock: s__('Terraform|Lock'),
    modalBody: s__(
      'Terraform|You are about to remove the State file %{name}. This will permanently delete all the State versions and history. The infrastructure provisioned previously	will remain intact, only the state file with all its versions are to be removed. This action is non-revertible.',
    ),
    modalCancel: s__('Terraform|Cancel'),
    modalHeader: s__('Terraform|Are you sure you want to remove the Terraform State %{name}?'),
    modalInputLabel: s__(
      'Terraform|To remove the State file and its versions, type %{name} to confirm:',
    ),
    modalRemove: s__('Terraform|Remove'),
    remove: s__('Terraform|Remove state file and versions'),
    unlock: s__('Terraform|Unlock'),
  },
  computed: {
    cancelModalProps() {
      return {
        text: this.$options.i18n.modalCancel,
        attributes: [],
      };
    },
    disableModalSubmit() {
      return this.removeConfirmText !== this.state.name;
    },
    primaryModalProps() {
      return {
        text: this.$options.i18n.modalRemove,
        attributes: [{ disabled: this.disableModalSubmit }, { variant: 'danger' }],
      };
    },
  },
  methods: {
    hideModal() {
      this.showRemoveModal = false;
      this.removeConfirmText = '';
    },
    lock() {
      this.stateMutation(lockState);
    },
    unlock() {
      this.stateMutation(unlockState);
    },
    remove() {
      if (!this.disableModalSubmit) {
        this.hideModal();
        this.stateMutation(removeState);
      }
    },
    stateMutation(mutation) {
      this.loading = true;
      this.$apollo
        .mutate({
          mutation,
          variables: {
            stateID: this.state.id,
          },
          refetchQueries: () => ['getStates'],
          awaitRefetchQueries: true,
          notifyOnNetworkStatusChange: true,
        })
        .catch(() => {})
        .finally(() => {
          this.loading = false;
        });
    },
  },
};
</script>

<template>
  <div>
    <gl-dropdown
      icon="ellipsis_v"
      right
      :data-testid="`terraform-state-actions-${state.name}`"
      :disabled="loading"
      toggle-class="gl-px-3! gl-shadow-none!"
    >
      <template #button-content>
        <gl-icon class="gl-mr-0" name="ellipsis_v" />
      </template>

      <gl-dropdown-item
        v-if="state.latestVersion"
        data-testid="terraform-state-download"
        :download="`${state.name}.json`"
        :href="state.latestVersion.downloadPath"
      >
        {{ $options.i18n.downloadJSON }}
      </gl-dropdown-item>

      <gl-dropdown-item v-if="state.lockedAt" data-testid="terraform-state-unlock" @click="unlock">
        {{ $options.i18n.unlock }}
      </gl-dropdown-item>

      <gl-dropdown-item v-else data-testid="terraform-state-lock" @click="lock">
        {{ $options.i18n.lock }}
      </gl-dropdown-item>

      <gl-dropdown-divider />

      <gl-dropdown-item data-testid="terraform-state-remove" @click="showRemoveModal = true">
        {{ $options.i18n.remove }}
      </gl-dropdown-item>
    </gl-dropdown>

    <gl-modal
      :modal-id="`terraform-state-actions-remove-modal-${state.name}`"
      :visible="showRemoveModal"
      :action-primary="primaryModalProps"
      :action-cancel="cancelModalProps"
      @ok="remove"
      @cancel="hideModal"
      @close="hideModal"
      @hide="hideModal"
    >
      <template #modal-title>
        <gl-sprintf :message="$options.i18n.modalHeader">
          <template #name>
            <span>{{ state.name }}</span>
          </template>
        </gl-sprintf>
      </template>

      <p>
        <gl-sprintf :message="$options.i18n.modalBody">
          <template #name>
            <span>{{ state.name }}</span>
          </template>
        </gl-sprintf>
      </p>

      <gl-form-group>
        <template #label>
          <gl-sprintf :message="$options.i18n.modalInputLabel">
            <template #name>
              <code>{{ state.name }}</code>
            </template>
          </gl-sprintf>
        </template>
        <gl-form-input
          :id="`terraform-state-remove-input-${state.name}`"
          ref="input"
          v-model="removeConfirmText"
          type="text"
          @keyup.enter="remove"
        />
      </gl-form-group>
    </gl-modal>
  </div>
</template>
