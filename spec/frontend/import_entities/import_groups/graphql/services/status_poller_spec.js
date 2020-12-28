import { createMockClient } from 'mock-apollo-client';
import { InMemoryCache } from 'apollo-cache-inmemory';
import waitForPromises from 'helpers/wait_for_promises';

import createFlash from '~/flash';
import { StatusPoller } from '~/import_entities/import_groups/graphql/services/status_poller';
import bulkImportSourceGroupsQuery from '~/import_entities/import_groups/graphql/queries/bulk_import_source_groups.query.graphql';
import { STATUSES } from '~/import_entities/constants';
import { SourceGroupsManager } from '~/import_entities/import_groups/graphql/services/source_groups_manager';
import { generateFakeEntry } from '../fixtures';

jest.mock('~/flash');
jest.mock('~/import_entities/import_groups/graphql/services/source_groups_manager', () => ({
  SourceGroupsManager: jest.fn().mockImplementation(function mock() {
    this.setImportStatus = jest.fn();
  }),
}));

const TEST_POLL_INTERVAL = 1000;

describe('Bulk import status poller', () => {
  let poller;
  let clientMock;

  const listQueryCacheCalls = () =>
    clientMock.readQuery.mock.calls.filter((call) => call[0].query === bulkImportSourceGroupsQuery);

  beforeEach(() => {
    clientMock = createMockClient({
      cache: new InMemoryCache({
        fragmentMatcher: { match: () => true },
      }),
    });

    jest.spyOn(clientMock, 'readQuery');

    poller = new StatusPoller({
      client: clientMock,
      interval: TEST_POLL_INTERVAL,
    });
  });

  describe('general behavior', () => {
    beforeEach(() => {
      clientMock.cache.writeQuery({
        query: bulkImportSourceGroupsQuery,
        data: { bulkImportSourceGroups: [] },
      });
    });

    it('does not perform polling when constructed', () => {
      jest.runOnlyPendingTimers();
      expect(listQueryCacheCalls()).toHaveLength(0);
    });

    it('immediately start polling when requested', async () => {
      await poller.startPolling();
      expect(listQueryCacheCalls()).toHaveLength(1);
    });

    it('constantly polls when started', async () => {
      poller.startPolling();
      expect(listQueryCacheCalls()).toHaveLength(1);

      jest.advanceTimersByTime(TEST_POLL_INTERVAL);
      expect(listQueryCacheCalls()).toHaveLength(2);

      jest.advanceTimersByTime(TEST_POLL_INTERVAL);
      expect(listQueryCacheCalls()).toHaveLength(3);
    });

    it('does not start polling when requested multiple times', async () => {
      poller.startPolling();
      expect(listQueryCacheCalls()).toHaveLength(1);

      poller.startPolling();
      expect(listQueryCacheCalls()).toHaveLength(1);
    });

    it('stops polling when requested', async () => {
      poller.startPolling();
      expect(listQueryCacheCalls()).toHaveLength(1);

      poller.stopPolling();
      jest.runOnlyPendingTimers();
      expect(listQueryCacheCalls()).toHaveLength(1);
    });

    it('does not query server when list is empty', async () => {
      jest.spyOn(clientMock, 'query');
      poller.startPolling();
      expect(clientMock.query).not.toHaveBeenCalled();
    });
  });

  it('does not query server when no groups have STARTED status', async () => {
    clientMock.cache.writeQuery({
      query: bulkImportSourceGroupsQuery,
      data: {
        bulkImportSourceGroups: [STATUSES.NONE, STATUSES.FINISHED].map((status, idx) =>
          generateFakeEntry({ status, id: idx }),
        ),
      },
    });

    jest.spyOn(clientMock, 'query');
    poller.startPolling();
    expect(clientMock.query).not.toHaveBeenCalled();
  });

  describe('when there are groups which have STARTED status', () => {
    const TARGET_NAMESPACE = 'root';

    const STARTED_GROUP_1 = {
      status: STATUSES.STARTED,
      id: 'started1',
      import_target: {
        target_namespace: TARGET_NAMESPACE,
        new_name: 'group1',
      },
    };

    const STARTED_GROUP_2 = {
      status: STATUSES.STARTED,
      id: 'started2',
      import_target: {
        target_namespace: TARGET_NAMESPACE,
        new_name: 'group2',
      },
    };

    const NOT_STARTED_GROUP = {
      status: STATUSES.NONE,
      id: 'not_started',
      import_target: {
        target_namespace: TARGET_NAMESPACE,
        new_name: 'group3',
      },
    };

    it('query server only for groups with STATUSES.STARTED', async () => {
      clientMock.cache.writeQuery({
        query: bulkImportSourceGroupsQuery,
        data: {
          bulkImportSourceGroups: [
            STARTED_GROUP_1,
            NOT_STARTED_GROUP,
            STARTED_GROUP_2,
          ].map((group) => generateFakeEntry(group)),
        },
      });

      clientMock.query = jest.fn().mockResolvedValue({ data: {} });
      poller.startPolling();

      expect(clientMock.query).toHaveBeenCalledTimes(1);
      await waitForPromises();
      const [[doc]] = clientMock.query.mock.calls;
      const { selections } = doc.query.definitions[0].selectionSet;
      expect(selections.every((field) => field.name.value === 'group')).toBeTruthy();
      expect(selections).toHaveLength(2);
      expect(selections.map((sel) => sel.arguments[0].value.value)).toStrictEqual([
        `${TARGET_NAMESPACE}/${STARTED_GROUP_1.import_target.new_name}`,
        `${TARGET_NAMESPACE}/${STARTED_GROUP_2.import_target.new_name}`,
      ]);
    });

    it('updates statuses only for groups in response', async () => {
      clientMock.cache.writeQuery({
        query: bulkImportSourceGroupsQuery,
        data: {
          bulkImportSourceGroups: [STARTED_GROUP_1, STARTED_GROUP_2].map((group) =>
            generateFakeEntry(group),
          ),
        },
      });

      clientMock.query = jest.fn().mockResolvedValue({ data: { group0: {} } });
      poller.startPolling();
      await waitForPromises();
      const [managerInstance] = SourceGroupsManager.mock.instances;
      expect(managerInstance.setImportStatus).toHaveBeenCalledTimes(1);
      expect(managerInstance.setImportStatus).toHaveBeenCalledWith(
        expect.objectContaining({ id: STARTED_GROUP_1.id }),
        STATUSES.FINISHED,
      );
    });

    describe('when error occurs', () => {
      beforeEach(() => {
        clientMock.cache.writeQuery({
          query: bulkImportSourceGroupsQuery,
          data: {
            bulkImportSourceGroups: [STARTED_GROUP_1, STARTED_GROUP_2].map((group) =>
              generateFakeEntry(group),
            ),
          },
        });

        clientMock.query = jest.fn().mockRejectedValue(new Error('dummy error'));
        poller.startPolling();
        return waitForPromises();
      });

      it('reports an error', () => {
        expect(createFlash).toHaveBeenCalled();
      });

      it('continues polling', async () => {
        jest.advanceTimersByTime(TEST_POLL_INTERVAL);
        expect(listQueryCacheCalls()).toHaveLength(2);
      });
    });
  });
});
