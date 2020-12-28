import {
  generateBadges,
  isGroup,
  isDirectMember,
  isCurrentUser,
  canRemove,
  canResend,
  canUpdate,
  canOverride,
  parseSortParam,
  buildSortHref,
} from '~/members/utils';
import { DEFAULT_SORT } from '~/members/constants';
import { member as memberMock, group, invite } from './mock_data';

const DIRECT_MEMBER_ID = 178;
const INHERITED_MEMBER_ID = 179;
const IS_CURRENT_USER_ID = 123;
const IS_NOT_CURRENT_USER_ID = 124;
const URL_HOST = 'https://localhost/';

describe('Members Utils', () => {
  describe('generateBadges', () => {
    it('has correct properties for each badge', () => {
      const badges = generateBadges(memberMock, true);

      badges.forEach((badge) => {
        expect(badge).toEqual(
          expect.objectContaining({
            show: expect.any(Boolean),
            text: expect.any(String),
            variant: expect.stringMatching(/muted|neutral|info|success|danger|warning/),
          }),
        );
      });
    });

    it.each`
      member                                                                     | expected
      ${memberMock}                                                              | ${{ show: true, text: "It's you", variant: 'success' }}
      ${{ ...memberMock, user: { ...memberMock.user, blocked: true } }}          | ${{ show: true, text: 'Blocked', variant: 'danger' }}
      ${{ ...memberMock, user: { ...memberMock.user, twoFactorEnabled: true } }} | ${{ show: true, text: '2FA', variant: 'info' }}
    `('returns expected output for "$expected.text" badge', ({ member, expected }) => {
      expect(generateBadges(member, true)).toContainEqual(expect.objectContaining(expected));
    });
  });

  describe('isGroup', () => {
    test.each`
      member        | expected
      ${group}      | ${true}
      ${memberMock} | ${false}
    `('returns $expected', ({ member, expected }) => {
      expect(isGroup(member)).toBe(expected);
    });
  });

  describe('isDirectMember', () => {
    test.each`
      sourceId               | expected
      ${DIRECT_MEMBER_ID}    | ${true}
      ${INHERITED_MEMBER_ID} | ${false}
    `('returns $expected', ({ sourceId, expected }) => {
      expect(isDirectMember(memberMock, sourceId)).toBe(expected);
    });
  });

  describe('isCurrentUser', () => {
    test.each`
      currentUserId             | expected
      ${IS_CURRENT_USER_ID}     | ${true}
      ${IS_NOT_CURRENT_USER_ID} | ${false}
    `('returns $expected', ({ currentUserId, expected }) => {
      expect(isCurrentUser(memberMock, currentUserId)).toBe(expected);
    });
  });

  describe('canRemove', () => {
    const memberCanRemove = {
      ...memberMock,
      canRemove: true,
    };

    test.each`
      member             | sourceId               | expected
      ${memberCanRemove} | ${DIRECT_MEMBER_ID}    | ${true}
      ${memberCanRemove} | ${INHERITED_MEMBER_ID} | ${false}
      ${memberMock}      | ${INHERITED_MEMBER_ID} | ${false}
    `('returns $expected', ({ member, sourceId, expected }) => {
      expect(canRemove(member, sourceId)).toBe(expected);
    });
  });

  describe('canResend', () => {
    test.each`
      member                                                           | expected
      ${invite}                                                        | ${true}
      ${{ ...invite, invite: { ...invite.invite, canResend: false } }} | ${false}
    `('returns $expected', ({ member, sourceId, expected }) => {
      expect(canResend(member, sourceId)).toBe(expected);
    });
  });

  describe('canUpdate', () => {
    const memberCanUpdate = {
      ...memberMock,
      canUpdate: true,
    };

    test.each`
      member             | currentUserId             | sourceId               | expected
      ${memberCanUpdate} | ${IS_NOT_CURRENT_USER_ID} | ${DIRECT_MEMBER_ID}    | ${true}
      ${memberCanUpdate} | ${IS_CURRENT_USER_ID}     | ${DIRECT_MEMBER_ID}    | ${false}
      ${memberCanUpdate} | ${IS_CURRENT_USER_ID}     | ${INHERITED_MEMBER_ID} | ${false}
      ${memberMock}      | ${IS_NOT_CURRENT_USER_ID} | ${DIRECT_MEMBER_ID}    | ${false}
    `('returns $expected', ({ member, currentUserId, sourceId, expected }) => {
      expect(canUpdate(member, currentUserId, sourceId)).toBe(expected);
    });
  });

  describe('canOverride', () => {
    it('returns `false`', () => {
      expect(canOverride(memberMock)).toBe(false);
    });
  });

  describe('parseSortParam', () => {
    beforeEach(() => {
      delete window.location;
      window.location = new URL(URL_HOST);
    });

    describe('when `sort` param is not present', () => {
      it('returns default sort options', () => {
        window.location.search = '';

        expect(parseSortParam(['account'])).toEqual(DEFAULT_SORT);
      });
    });

    describe('when field passed in `sortableFields` argument does not have `sort` key defined', () => {
      it('returns default sort options', () => {
        window.location.search = '?sort=source_asc';

        expect(parseSortParam(['source'])).toEqual(DEFAULT_SORT);
      });
    });

    describe.each`
      sortParam              | expected
      ${'name_asc'}          | ${{ sortByKey: 'account', sortDesc: false }}
      ${'name_desc'}         | ${{ sortByKey: 'account', sortDesc: true }}
      ${'last_joined'}       | ${{ sortByKey: 'granted', sortDesc: false }}
      ${'oldest_joined'}     | ${{ sortByKey: 'granted', sortDesc: true }}
      ${'access_level_asc'}  | ${{ sortByKey: 'maxRole', sortDesc: false }}
      ${'access_level_desc'} | ${{ sortByKey: 'maxRole', sortDesc: true }}
      ${'recent_sign_in'}    | ${{ sortByKey: 'lastSignIn', sortDesc: false }}
      ${'oldest_sign_in'}    | ${{ sortByKey: 'lastSignIn', sortDesc: true }}
    `('when `sort` query string param is `$sortParam`', ({ sortParam, expected }) => {
      it(`returns ${JSON.stringify(expected)}`, async () => {
        window.location.search = `?sort=${sortParam}`;

        expect(parseSortParam(['account', 'granted', 'expires', 'maxRole', 'lastSignIn'])).toEqual(
          expected,
        );
      });
    });
  });

  describe('buildSortHref', () => {
    beforeEach(() => {
      delete window.location;
      window.location = new URL(URL_HOST);
    });

    describe('when field passed in `sortBy` argument does not have `sort` key defined', () => {
      it('returns an empty string', () => {
        expect(
          buildSortHref({
            sortBy: 'source',
            sortDesc: false,
            filteredSearchBarTokens: [],
            filteredSearchBarSearchParam: 'search',
          }),
        ).toBe('');
      });
    });

    describe('when there are no filter params set', () => {
      it('sets `sort` param', () => {
        expect(
          buildSortHref({
            sortBy: 'account',
            sortDesc: false,
            filteredSearchBarTokens: [],
            filteredSearchBarSearchParam: 'search',
          }),
        ).toBe(`${URL_HOST}?sort=name_asc`);
      });
    });

    describe('when filter params are set', () => {
      it('merges the `sort` param with the filter params', () => {
        window.location.search = '?two_factor=enabled&with_inherited_permissions=exclude';

        expect(
          buildSortHref({
            sortBy: 'account',
            sortDesc: false,
            filteredSearchBarTokens: ['two_factor', 'with_inherited_permissions'],
            filteredSearchBarSearchParam: 'search',
          }),
        ).toBe(`${URL_HOST}?two_factor=enabled&with_inherited_permissions=exclude&sort=name_asc`);
      });
    });

    describe('when search param is set', () => {
      it('merges the `sort` param with the search param', () => {
        window.location.search = '?search=foobar';

        expect(
          buildSortHref({
            sortBy: 'account',
            sortDesc: false,
            filteredSearchBarTokens: ['two_factor', 'with_inherited_permissions'],
            filteredSearchBarSearchParam: 'search',
          }),
        ).toBe(`${URL_HOST}?search=foobar&sort=name_asc`);
      });
    });
  });
});
