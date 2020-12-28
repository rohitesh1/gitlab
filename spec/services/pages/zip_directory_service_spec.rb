# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::ZipDirectoryService do
  it 'raises error if project pages dir does not exist' do
    expect do
      described_class.new("/tmp/not/existing/dir").execute
    end.to raise_error(described_class::InvalidArchiveError)
  end

  context 'when work dir exists' do
    around do |example|
      Dir.mktmpdir do |dir|
        @work_dir = dir
        example.run
      end
    end

    let(:result) do
      described_class.new(@work_dir).execute
    end

    let(:archive) { result.first }
    let(:entries_count) { result.second }

    it 'raises error if there is no public directory and does not leave archive' do
      expect { archive }.to raise_error(described_class::InvalidArchiveError)

      expect(File.exist?(File.join(@work_dir, '@migrated.zip'))).to eq(false)
    end

    it 'raises error if public directory is a symlink' do
      create_dir('target')
      create_file('./target/index.html', 'hello')
      create_link("public", "./target")

      expect { archive }.to raise_error(described_class::InvalidArchiveError)
    end

    context 'when there is a public directory' do
      before do
        create_dir('public')
      end

      it 'creates the file next the public directory' do
        expect(archive).to eq(File.join(@work_dir, "@migrated.zip"))
      end

      it 'includes public directory' do
        with_zip_file do |zip_file|
          entry = zip_file.get_entry("public/")
          expect(entry.ftype).to eq(:directory)
        end
      end

      it 'returns number of entries' do
        create_file("public/index.html", "hello")
        create_link("public/link.html", "./index.html")
        expect(entries_count).to eq(3) # + 'public' directory
      end

      it 'removes the old file if it exists' do
        # simulate the old run
        described_class.new(@work_dir).execute

        with_zip_file do |zip_file|
          expect(zip_file.entries.count).to eq(1)
        end
      end

      it 'ignores other top level files and directories' do
        create_file("top_level.html", "hello")
        create_dir("public2")

        with_zip_file do |zip_file|
          expect { zip_file.get_entry("top_level.html") }.to raise_error(Errno::ENOENT)
          expect { zip_file.get_entry("public2/") }.to raise_error(Errno::ENOENT)
        end
      end

      it 'includes index.html file' do
        create_file("public/index.html", "Hello!")

        with_zip_file do |zip_file|
          entry = zip_file.get_entry("public/index.html")
          expect(zip_file.read(entry)).to eq("Hello!")
        end
      end

      it 'includes hidden file' do
        create_file("public/.hidden.html", "Hello!")

        with_zip_file do |zip_file|
          entry = zip_file.get_entry("public/.hidden.html")
          expect(zip_file.read(entry)).to eq("Hello!")
        end
      end

      it 'includes nested directories and files' do
        create_dir("public/nested")
        create_dir("public/nested/nested2")
        create_file("public/nested/nested2/nested.html", "Hello nested")

        with_zip_file do |zip_file|
          entry = zip_file.get_entry("public/nested")
          expect(entry.ftype).to eq(:directory)

          entry = zip_file.get_entry("public/nested/nested2")
          expect(entry.ftype).to eq(:directory)

          entry = zip_file.get_entry("public/nested/nested2/nested.html")
          expect(zip_file.read(entry)).to eq("Hello nested")
        end
      end

      it 'adds a valid symlink' do
        create_file("public/target.html", "hello")
        create_link("public/link.html", "./target.html")

        with_zip_file do |zip_file|
          entry = zip_file.get_entry("public/link.html")
          expect(entry.ftype).to eq(:symlink)
          expect(zip_file.read(entry)).to eq("./target.html")
        end
      end

      it 'ignores the symlink pointing outside of public directory' do
        create_file("target.html", "hello")
        create_link("public/link.html", "../target.html")

        with_zip_file do |zip_file|
          expect { zip_file.get_entry("public/link.html") }.to raise_error(Errno::ENOENT)
        end
      end

      it 'ignores the symlink if target is absent' do
        create_link("public/link.html", "./target.html")

        with_zip_file do |zip_file|
          expect { zip_file.get_entry("public/link.html") }.to raise_error(Errno::ENOENT)
        end
      end

      it 'ignores symlink if is absolute and points to outside of directory' do
        target = File.join(@work_dir, "target")
        FileUtils.touch(target)

        create_link("public/link.html", target)

        with_zip_file do |zip_file|
          expect { zip_file.get_entry("public/link.html") }.to raise_error(Errno::ENOENT)
        end
      end

      it "includes raw symlink if it's target is a valid directory" do
        create_dir("public/target")
        create_file("public/target/index.html", "hello")
        create_link("public/link", "./target")

        with_zip_file do |zip_file|
          expect(zip_file.entries.count).to eq(4) # /public and 3 created above

          entry = zip_file.get_entry("public/link")
          expect(entry.ftype).to eq(:symlink)
          expect(zip_file.read(entry)).to eq("./target")
        end
      end
    end

    context "validating fixtures pages archives" do
      using RSpec::Parameterized::TableSyntax

      where(:fixture_path) do
        ["spec/fixtures/pages.zip", "spec/fixtures/pages_non_writeable.zip"]
      end

      with_them do
        let(:full_fixture_path) { Rails.root.join(fixture_path) }

        it 'a created archives contains exactly the same entries' do
          SafeZip::Extract.new(full_fixture_path).extract(directories: ['public'], to: @work_dir)

          with_zip_file do |created_archive|
            Zip::File.open(full_fixture_path) do |original_archive|
              original_archive.entries do |original_entry|
                created_entry = created_archive.get_entry(original_entry.name)

                expect(created_entry.name).to eq(original_entry.name)
                expect(created_entry.ftype).to eq(original_entry.ftype)
                expect(created_archive.read(created_entry)).to eq(original_archive.read(original_entry))
              end
            end
          end
        end
      end
    end

    def create_file(name, content)
      File.open(File.join(@work_dir, name), "w") do |f|
        f.write(content)
      end
    end

    def create_dir(dir)
      Dir.mkdir(File.join(@work_dir, dir))
    end

    def create_link(new_name, target)
      File.symlink(target, File.join(@work_dir, new_name))
    end

    def with_zip_file
      Zip::File.open(archive) do |zip_file|
        yield zip_file
      end
    end
  end
end
