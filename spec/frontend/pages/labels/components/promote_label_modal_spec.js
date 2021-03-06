import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import { TEST_HOST } from 'jest/helpers/test_constants';
import promoteLabelModal from '~/pages/projects/labels/components/promote_label_modal.vue';
import eventHub from '~/pages/projects/labels/event_hub';
import axios from '~/lib/utils/axios_utils';

describe('Promote label modal', () => {
  let vm;
  const Component = Vue.extend(promoteLabelModal);
  const labelMockData = {
    labelTitle: 'Documentation',
    labelColor: '#5cb85c',
    labelTextColor: '#ffffff',
    url: `${TEST_HOST}/dummy/promote/labels`,
    groupName: 'group',
  };

  describe('Modal title and description', () => {
    beforeEach(() => {
      vm = mountComponent(Component, labelMockData);
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('contains the proper description', () => {
      expect(vm.text).toContain(
        `Promoting ${labelMockData.labelTitle} will make it available for all projects inside ${labelMockData.groupName}`,
      );
    });

    it('contains a label span with the color', () => {
      expect(vm.labelColor).not.toBe(null);
      expect(vm.labelColor).toBe(labelMockData.labelColor);
      expect(vm.labelTitle).toBe(labelMockData.labelTitle);
    });
  });

  describe('When requesting a label promotion', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        ...labelMockData,
      });
      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('redirects when a label is promoted', (done) => {
      const responseURL = `${TEST_HOST}/dummy/endpoint`;
      jest.spyOn(axios, 'post').mockImplementation((url) => {
        expect(url).toBe(labelMockData.url);
        expect(eventHub.$emit).toHaveBeenCalledWith(
          'promoteLabelModal.requestStarted',
          labelMockData.url,
        );
        return Promise.resolve({
          request: {
            responseURL,
          },
        });
      });

      vm.onSubmit()
        .then(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('promoteLabelModal.requestFinished', {
            labelUrl: labelMockData.url,
            successful: true,
          });
        })
        .then(done)
        .catch(done.fail);
    });

    it('displays an error if promoting a label failed', (done) => {
      const dummyError = new Error('promoting label failed');
      dummyError.response = { status: 500 };
      jest.spyOn(axios, 'post').mockImplementation((url) => {
        expect(url).toBe(labelMockData.url);
        expect(eventHub.$emit).toHaveBeenCalledWith(
          'promoteLabelModal.requestStarted',
          labelMockData.url,
        );
        return Promise.reject(dummyError);
      });

      vm.onSubmit()
        .catch((error) => {
          expect(error).toBe(dummyError);
          expect(eventHub.$emit).toHaveBeenCalledWith('promoteLabelModal.requestFinished', {
            labelUrl: labelMockData.url,
            successful: false,
          });
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
