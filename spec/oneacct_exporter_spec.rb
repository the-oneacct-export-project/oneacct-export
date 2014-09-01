require 'spec_helper'
require 'ostruct'

Sidekiq::Testing.fake!

describe OneacctExporter do
  subject { oneacct_exporter }

  let(:oneacct_exporter) { OneacctExporter.new({}, {}, Logger.new('/dev/null')) }

  describe '#new' do
    it 'returns an instance of OneacctExporter' do
      expect(OneacctExporter.new({}, {}, 'fake_logger')).to be_instance_of(OneacctExporter)
    end

    context 'with arguments' do
      let(:range) { {1 => 2, 3 => 4} }
      let(:groups) { {5 => 6, 7 => 8} }
      let(:logger) { 'fake_logger' }

      it 'correctly assignes the arguments' do
        oe = OneacctExporter.new(range, groups, logger)
        expect(oe.log).to eq(logger)
        expect(oe.groups).to eq(groups)
        expect(oe.range).to eq(range)
      end
    end
  end

  describe '.export' do
    before :example do
      allow(subject).to receive(:clean_output_dir)
      allow(OneDataAccessor).to receive(:new) { oda }
    end

    let(:oda) { double('oda') }

    context 'with increasing batch number' do
      before :example do
        expect(oda).to receive(:vms).with(0, {}, {}).ordered { [1, 2, 3] }
        expect(oda).to receive(:vms).with(1, {}, {}).ordered { [4, 5, 6] }
        expect(oda).to receive(:vms).with(2, {}, {}).ordered { [7, 8, 9] }
        expect(oda).to receive(:vms).with(3, {}, {}).ordered { nil }
      end

      it 'will always finish when there are no more vms to process' do
        subject.export
      end
    end

    context 'with non-empty batches of vms' do
      before :example do
        Sidekiq::Worker.clear_all
        allow(oda).to receive(:vms).with(0, {}, {}).ordered { [1, 2, 3] }
        allow(oda).to receive(:vms).with(1, {}, {}).ordered { [4, 5, 6] }
        allow(oda).to receive(:vms).with(2, {}, {}).ordered { [7, 8, 9] }
        allow(oda).to receive(:vms).with(3, {}, {}).ordered { nil }
      end

      after :example do
        Sidekiq::Worker.clear_all
      end
        
      it 'starts worker for every vm batch' do
        subject.export
        expect(OneWorker.jobs.size).to eq(3)
      end

      it 'starts worker with right vms' do
        subject.export
        expect(OneWorker.jobs[0]['args'][0]).to eq('1|2|3')
        expect(OneWorker.jobs[1]['args'][0]).to eq('4|5|6')
        expect(OneWorker.jobs[2]['args'][0]).to eq('7|8|9')
      end
    end

    context 'with some empty batches of vms' do
      before :example do
        Sidekiq::Worker.clear_all
        allow(oda).to receive(:vms).with(0, {}, {}).ordered { [1, 2, 3] }
        allow(oda).to receive(:vms).with(1, {}, {}).ordered { [] }
        allow(oda).to receive(:vms).with(2, {}, {}).ordered { [7, 8, 9] }
        allow(oda).to receive(:vms).with(3, {}, {}).ordered { [] }
        allow(oda).to receive(:vms).with(4, {}, {}).ordered { nil }
      end

      after :example do
        Sidekiq::Worker.clear_all
      end
        
      it 'starts worker for every non-empty vm batch' do
        subject.export
        expect(OneWorker.jobs.size).to eq(2)
      end
    end
  end

  describe '.clean_output_dir' do
    let(:testdir_path) { "mock/oneacct_exporter_testdir" }

    before :example do
      Settings.output['output_dir'] = testdir_path
      Dir.mkdir(testdir_path)
    end

    after :example do
      FileUtils.remove_dir(testdir_path, true)
    end

    context 'with empty output directory' do
      it 'remains empty' do
        subject.clean_output_dir
        expect(Dir.entries(testdir_path).count).to eq(2)
      end
    end

    context 'with not related files' do
      before :example do
        FileUtils.touch("#{testdir_path}/aa")
        FileUtils.touch("#{testdir_path}/11")
        FileUtils.touch("#{testdir_path}/aa11")
        FileUtils.touch("#{testdir_path}/11aa")
        FileUtils.touch("#{testdir_path}/0")
        FileUtils.touch("#{testdir_path}/01")
        FileUtils.touch("#{testdir_path}/0000000000001")
      end

      it 'keeps non-related files in the directory' do
        subject.clean_output_dir
        expect(Dir.entries(testdir_path).count).to eq(9)
      end
    end

    context 'with related files' do
      before :example do
        FileUtils.touch("#{testdir_path}/00000000000001")
        FileUtils.touch("#{testdir_path}/00000000000002")
        FileUtils.touch("#{testdir_path}/00000000000003")
        FileUtils.touch("#{testdir_path}/00000000000004")
        FileUtils.touch("#{testdir_path}/00000000000005")
        FileUtils.touch("#{testdir_path}/00000000000006")
      end

      it 'removes all files and leaves directory empty' do
        subject.clean_output_dir
        expect(Dir.entries(testdir_path).count).to eq(2)
      end
    end

    context 'with both related and on-related files' do
      before :example do
        FileUtils.touch("#{testdir_path}/00000000000001")
        FileUtils.touch("#{testdir_path}/00000000000002")
        FileUtils.touch("#{testdir_path}/00000000000003")
        FileUtils.touch("#{testdir_path}/00000000000004")
        FileUtils.touch("#{testdir_path}/00000000000005")
        FileUtils.touch("#{testdir_path}/00000000000006")
        FileUtils.touch("#{testdir_path}/aa")
        FileUtils.touch("#{testdir_path}/11")
        FileUtils.touch("#{testdir_path}/aa11")
        FileUtils.touch("#{testdir_path}/11aa")
        FileUtils.touch("#{testdir_path}/0")
        FileUtils.touch("#{testdir_path}/01")
        FileUtils.touch("#{testdir_path}/0000000000001")
      end

      it 'removes all related files and keeps all non-related files' do
        subject.clean_output_dir
        expect(Dir.entries(testdir_path).count).to eq(9)
      end
    end
  end
end
