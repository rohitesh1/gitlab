<script>
import { GlFormCheckbox } from '@gitlab/ui';

export default {
  components: {
    GlFormCheckbox,
  },
  props: {
    hideBacklogList: {
      type: Boolean,
      required: true,
    },
    hideClosedList: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-mb-5">
    <label class="label-bold gl-font-lg" for="board-new-name">
      {{ __('List options') }}
    </label>
    <p class="text-secondary gl-mb-3">
      {{ __('Configure which lists are shown for anyone who visits this board') }}
    </p>
    <gl-form-checkbox
      :checked="!hideBacklogList"
      data-testid="backlog-list-checkbox"
      @change="$emit('update:hideBacklogList', !hideBacklogList)"
      >{{ __('Show the Open list') }}
    </gl-form-checkbox>
    <gl-form-checkbox
      :checked="!hideClosedList"
      data-testid="closed-list-checkbox"
      @change="$emit('update:hideClosedList', !hideClosedList)"
      >{{ __('Show the Closed list') }}
    </gl-form-checkbox>
  </div>
</template>
