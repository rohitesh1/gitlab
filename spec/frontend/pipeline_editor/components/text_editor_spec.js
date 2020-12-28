import { shallowMount } from '@vue/test-utils';
import {
  mockCiConfigPath,
  mockCiYml,
  mockCommitSha,
  mockProjectPath,
  mockNamespace,
  mockProjectName,
} from '../mock_data';

import TextEditor from '~/pipeline_editor/components/text_editor.vue';

describe('~/pipeline_editor/components/text_editor.vue', () => {
  let wrapper;

  let editorReadyListener;
  let mockUse;
  let mockRegisterCiSchema;

  const MockEditorLite = {
    template: '<div/>',
    props: ['value', 'fileName'],
    mounted() {
      this.$emit('editor-ready');
    },
    methods: {
      getEditor: () => ({
        use: mockUse,
        registerCiSchema: mockRegisterCiSchema,
      }),
    },
  };

  const createComponent = (opts = {}, mountFn = shallowMount) => {
    wrapper = mountFn(TextEditor, {
      propsData: {
        ciConfigPath: mockCiConfigPath,
        commitSha: mockCommitSha,
        projectPath: mockProjectPath,
      },
      attrs: {
        value: mockCiYml,
      },
      listeners: {
        'editor-ready': editorReadyListener,
      },
      stubs: {
        EditorLite: MockEditorLite,
      },
      ...opts,
    });
  };

  const findEditor = () => wrapper.find(MockEditorLite);

  beforeEach(() => {
    editorReadyListener = jest.fn();
    mockUse = jest.fn();
    mockRegisterCiSchema = jest.fn();

    createComponent();
  });

  it('contains an editor', () => {
    expect(findEditor().exists()).toBe(true);
  });

  it('editor contains the value provided', () => {
    expect(findEditor().props('value')).toBe(mockCiYml);
  });

  it('editor is configured for the CI config path', () => {
    expect(findEditor().props('fileName')).toBe(mockCiConfigPath);
  });

  it('editor is configured with syntax highligting', async () => {
    expect(mockUse).toHaveBeenCalledTimes(1);
    expect(mockRegisterCiSchema).toHaveBeenCalledTimes(1);
    expect(mockRegisterCiSchema).toHaveBeenCalledWith({
      projectNamespace: mockNamespace,
      projectPath: mockProjectName,
      ref: mockCommitSha,
    });
  });

  it('bubbles up events', () => {
    findEditor().vm.$emit('editor-ready');

    expect(editorReadyListener).toHaveBeenCalled();
  });
});
