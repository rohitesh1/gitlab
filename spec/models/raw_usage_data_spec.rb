# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RawUsageData do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:payload) }
    it { is_expected.to validate_presence_of(:recorded_at) }

    context 'uniqueness validation' do
      let!(:existing_record) { create(:raw_usage_data) }

      it { is_expected.to validate_uniqueness_of(:recorded_at) }
    end

    describe '#update_sent_at!' do
      let(:raw_usage_data) { create(:raw_usage_data) }

      it 'updates sent_at' do
        raw_usage_data.update_sent_at!

        expect(raw_usage_data.sent_at).not_to be_nil
      end
    end
  end
end
