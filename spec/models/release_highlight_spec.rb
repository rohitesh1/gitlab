# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleaseHighlight do
  let(:fixture_dir_glob) { Dir.glob(File.join('spec', 'fixtures', 'whats_new', '*.yml')) }

  before do
    allow(Dir).to receive(:glob).with(Rails.root.join('data', 'whats_new', '*.yml')).and_return(fixture_dir_glob)
  end

  after do
    ReleaseHighlight.instance_variable_set(:@file_paths, nil)
  end

  describe '.for_version' do
    subject { ReleaseHighlight.for_version(version: version) }

    let(:version) { '1.1' }

    context 'with version param that exists' do
      it 'returns items from that version' do
        expect(subject.items.first['title']).to eq("It's gonna be a bright")
      end
    end

    context 'with version param that does NOT exist' do
      let(:version) { '84.0' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '.paginated' do
    let(:dot_com) { false }

    before do
      allow(Gitlab).to receive(:com?).and_return(dot_com)
    end

    context 'with page param' do
      subject { ReleaseHighlight.paginated(page: page) }

      context 'when there is another page of results' do
        let(:page) { 2 }

        it 'responds with paginated results' do
          expect(subject[:items].first['title']).to eq('bright')
          expect(subject[:next_page]).to eq(3)
        end
      end

      context 'when there is NOT another page of results' do
        let(:page) { 3 }

        it 'responds with paginated results and no next_page' do
          expect(subject[:items].first['title']).to eq("It's gonna be a bright")
          expect(subject[:next_page]).to eq(nil)
        end
      end

      context 'when that specific page does not exist' do
        let(:page) { 84 }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end

    context 'with no page param' do
      subject { ReleaseHighlight.paginated }

      it 'uses multiple levels of cache' do
        expect(Rails.cache).to receive(:fetch).with("release_highlight:items:page-1:#{Gitlab.revision}", { expires_in: described_class::CACHE_DURATION }).and_call_original
        expect(Rails.cache).to receive(:fetch).with("release_highlight:file_paths:#{Gitlab.revision}", { expires_in: described_class::CACHE_DURATION }).and_call_original

        subject
      end

      it 'returns platform specific items' do
        expect(subject[:items].count).to eq(1)
        expect(subject[:items].first['title']).to eq("bright and sunshinin' day")
        expect(subject[:next_page]).to eq(2)
      end

      it 'parses the body as markdown and returns html' do
        expect(subject[:items].first['body']).to match("<h2 id=\"bright-and-sunshinin-day\">bright and sunshinin’ day</h2>")
      end

      it 'logs an error if theres an error parsing markdown for an item, and skips it' do
        allow(Kramdown::Document).to receive(:new).and_raise

        expect(Gitlab::ErrorTracking).to receive(:track_exception)
        expect(subject[:items]).to be_empty
      end

      context 'when Gitlab.com' do
        let(:dot_com) { true }

        it 'responds with a different set of data' do
          expect(subject[:items].count).to eq(1)
          expect(subject[:items].first['title']).to eq("I think I can make it now the pain is gone")
        end
      end

      context 'YAML parsing throws an exception' do
        it 'fails gracefully and logs an error' do
          allow(YAML).to receive(:safe_load).and_raise(Psych::Exception)

          expect(Gitlab::ErrorTracking).to receive(:track_exception)
          expect(subject).to be_nil
        end
      end
    end
  end

  describe '.most_recent_item_count' do
    subject { ReleaseHighlight.most_recent_item_count }

    it 'uses process memory cache' do
      expect(Gitlab::ProcessMemoryCache.cache_backend).to receive(:fetch).with("release_highlight:recent_item_count:#{Gitlab.revision}", expires_in: described_class::CACHE_DURATION)

      subject
    end

    context 'when recent release items exist' do
      it 'returns the count from the most recent file' do
        allow(ReleaseHighlight).to receive(:paginated).and_return(double(:paginated, items: [double(:item)]))

        expect(subject).to eq(1)
      end
    end

    context 'when recent release items do NOT exist' do
      it 'returns nil' do
        allow(ReleaseHighlight).to receive(:paginated).and_return(nil)

        expect(subject).to be_nil
      end
    end
  end

  describe '.versions' do
    subject { described_class.versions }

    it 'uses process memory cache' do
      expect(Gitlab::ProcessMemoryCache.cache_backend).to receive(:fetch).with("release_highlight:versions:#{Gitlab.revision}", { expires_in: described_class::CACHE_DURATION })

      subject
    end

    it 'returns versions from the file paths' do
      expect(subject).to eq(['1.5', '1.2', '1.1'])
    end

    context 'when there are more than 12 versions' do
      let(:file_paths) do
        i = 0
        Array.new(20) { "20201225_01_#{i += 1}.yml" }
      end

      it 'limits to 12 versions' do
        allow(ReleaseHighlight).to receive(:file_paths).and_return(file_paths)
        expect(subject.count).to eq(12)
      end
    end
  end

  describe 'QueryResult' do
    subject { ReleaseHighlight::QueryResult.new(items: items, next_page: 2) }

    let(:items) { [:item] }

    it 'responds to map' do
      expect(subject.map(&:to_s)).to eq(items.map(&:to_s))
    end
  end
end
