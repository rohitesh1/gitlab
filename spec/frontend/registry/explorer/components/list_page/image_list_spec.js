import { shallowMount } from '@vue/test-utils';
import { GlKeysetPagination } from '@gitlab/ui';
import Component from '~/registry/explorer/components/list_page/image_list.vue';
import ImageListRow from '~/registry/explorer/components/list_page/image_list_row.vue';

import { imagesListResponse, pageInfo as defaultPageInfo } from '../../mock_data';

describe('Image List', () => {
  let wrapper;

  const findRow = () => wrapper.findAll(ImageListRow);
  const findPagination = () => wrapper.find(GlKeysetPagination);

  const mountComponent = (pageInfo = defaultPageInfo) => {
    wrapper = shallowMount(Component, {
      propsData: {
        images: imagesListResponse,
        pageInfo,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('list', () => {
    it('contains one list element for each image', () => {
      mountComponent();

      expect(findRow().length).toBe(imagesListResponse.length);
    });

    it('when delete event is emitted on the row it emits up a delete event', () => {
      mountComponent();

      findRow().at(0).vm.$emit('delete', 'foo');
      expect(wrapper.emitted('delete')).toEqual([['foo']]);
    });
  });

  describe('pagination', () => {
    it('exists', () => {
      mountComponent();

      expect(findPagination().exists()).toBe(true);
    });

    it.each`
      hasNextPage | hasPreviousPage | isVisible
      ${true}     | ${true}         | ${true}
      ${true}     | ${false}        | ${true}
      ${false}    | ${true}         | ${true}
    `(
      'when hasNextPage is $hasNextPage and hasPreviousPage is $hasPreviousPage: is $isVisible that the component is visible',
      ({ hasNextPage, hasPreviousPage, isVisible }) => {
        mountComponent({ hasNextPage, hasPreviousPage });

        expect(findPagination().exists()).toBe(isVisible);
        expect(findPagination().props('hasPreviousPage')).toBe(hasPreviousPage);
        expect(findPagination().props('hasNextPage')).toBe(hasNextPage);
      },
    );

    it('emits "prev-page" when the user clicks the back page button', () => {
      mountComponent({ hasPreviousPage: true });

      findPagination().vm.$emit('prev');

      expect(wrapper.emitted('prev-page')).toEqual([[]]);
    });

    it('emits "next-page" when the user clicks the forward page button', () => {
      mountComponent({ hasNextPage: true });

      findPagination().vm.$emit('next');

      expect(wrapper.emitted('next-page')).toEqual([[]]);
    });
  });
});
