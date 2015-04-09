require 'spec_helper'
require 'ostruct'

Sidekiq::Testing.fake!

describe OneacctExporter do
  subject { oneacct_exporter }

  let(:oneacct_exporter) { OneacctExporter.new({}, Logger.new('/dev/null')) }

  describe '#new' do
    it 'returns an instance of OneacctExporter' do
      expect(OneacctExporter.new({}, 'fake_logger')).to be_instance_of(OneacctExporter)
    end

    context 'with arguments' do
      let(:range) { { 1 => 2, 3 => 4 } }
      let(:groups) { { 5 => 6, 7 => 8 } }
      let(:timeout) { 42 }
      let(:blocking) { true }
      let(:logger) { 'fake_logger' }
      let(:opts) { { range: range, groups: groups, timeout: timeout, blocking: blocking } }

      it 'correctly assignes the arguments' do
        oe = OneacctExporter.new(opts, logger)
        expect(oe.log).to eq(logger)
        expect(oe.groups).to eq(groups)
        expect(oe.range).to eq(range)
        expect(oe.blocking).to eq(blocking)
        expect(oe.timeout).to eq(timeout)
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
        expect(oda).to receive(:vms).with(0, nil, nil).ordered { [1, 2, 3] }
        expect(oda).to receive(:vms).with(1, nil, nil).ordered { [4, 5, 6] }
        expect(oda).to receive(:vms).with(2, nil, nil).ordered { [7, 8, 9] }
        expect(oda).to receive(:vms).with(3, nil, nil).ordered { nil }
      end

      it 'will always finish when there are no more vms to process' do
        subject.export
      end
    end

    context 'with non-empty batches of vms' do
      before :example do
        Sidekiq::Worker.clear_all
        allow(oda).to receive(:vms).with(0, nil, nil).ordered { [1, 2, 3] }
        allow(oda).to receive(:vms).with(1, nil, nil).ordered { [4, 5, 6] }
        allow(oda).to receive(:vms).with(2, nil, nil).ordered { [7, 8, 9] }
        allow(oda).to receive(:vms).with(3, nil, nil).ordered { nil }
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
        allow(oda).to receive(:vms).with(0, nil, nil).ordered { [1, 2, 3] }
        allow(oda).to receive(:vms).with(1, nil, nil).ordered { [] }
        allow(oda).to receive(:vms).with(2, nil, nil).ordered { [7, 8, 9] }
        allow(oda).to receive(:vms).with(3, nil, nil).ordered { [] }
        allow(oda).to receive(:vms).with(4, nil, nil).ordered { nil }
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
    let(:testdir_path) { "#{GEM_DIR}/mock/oneacct_exporter_testdir" }

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

    context 'with files in output directory' do
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
  end

  describe '.all_workers_done?' do
    context 'with all workers done' do
      before :example do
        allow(Sidekiq::Workers).to receive(:new) { [] }
      end

      it 'returns true' do
        expect(subject.all_workers_done?).to be true
      end
    end

    context 'with some workers still processing' do
      before :example do
        allow(Sidekiq::Workers).to receive(:new) { [1, 2] }
      end

      it 'returns false' do
        expect(subject.all_workers_done?).to be false
      end
    end
  end

  describe '.queue_empty?' do
    before :example do
      Settings.sidekiq['queue'] = 'oneacct_export_test'
      stats = double('stats')
      allow(Sidekiq::Stats).to receive(:new) { stats }
      allow(stats).to receive(:queues) { queues }
    end

    let(:queues) { { 'queue1' => 5, 'queue2' => 0, 'oneacct_export_test' => 0, 'queue3' => 7 } }

    context 'with empty queue' do
      it 'returns true' do
        expect(subject.queue_empty?).to be true
      end
    end

    context 'with empty queue' do
      before :example do
        queues['oneacct_export_test'] = 10
      end

      it 'returns false' do
        expect(subject.queue_empty?).to be false
      end
    end

    context 'with empty queue' do
      before :example do
        queues.delete 'oneacct_export_test'
      end

      it 'returns true' do
        expect(subject.queue_empty?).to be true
      end
    end
  end

  describe '.wait_for_processing' do
    let(:oneacct_exporter) { OneacctExporter.new({ timeout: 120 }, Logger.new('/dev/null')) }

    context 'without timeout' do
      it 'ends naturally' do
        expect(subject).to receive(:queue_empty?).and_return(false, false, true, true, true)
        expect(subject).to receive(:all_workers_done?).and_return(false, false, true)

        subject.wait_for_processing
      end
    end

    context 'with unfinished processing and exceeded timeout' do
      let(:oneacct_exporter) { OneacctExporter.new({ timeout: 20 }, Logger.new('/dev/null')) }

      it 'ends program' do
        allow(subject).to receive(:queue_empty?) { false }
        allow(subject).to receive(:all_workers_done?) { false }
        expect(subject.log).to receive(:error)

        subject.wait_for_processing
      end
    end
  end
end
