require 'spec_helper'

module DataValidators
  describe DataCompute do

    describe '.sum_disk_size' do
      let(:vm) do
        xml = File.read("#{GEM_DIR}/mock/#{filename}")
        OpenNebula::XMLElement.new(OpenNebula::XMLElement.build_xml(xml, 'VM'))
      end

      context 'vm with DISK without SIZE' do
        let(:filename) { 'one_worker_valid_machine.xml' }

        it 'returns NULL' do
          expect(subject.sum_disk_size(vm)).to eq('NULL')
        end
      end

      context 'vm with DISK with invalid SIZE' do
        let(:filename) { 'one_worker_DISK_SIZE_nan.xml' }

        it 'returns NULL' do
          expect(subject.sum_disk_size(vm)).to eq('NULL')
        end
      end

      context 'vm with single DISK and valid SIZE' do
        let(:filename) { 'one_worker_vm7.xml' }

        it 'return correct disk size' do
          expect(subject.sum_disk_size(vm)).to eq(11)
        end
      end

      context 'vm with multiple DISKs and valid SIZE' do
        let(:filename) { 'one_worker_vm8.xml' }

        it 'return correct disk size' do
          expect(subject.sum_disk_size(vm)).to eq(53)
        end
      end
    end

    describe '.sum_rstime' do
      let(:vm) do
        xml = File.read("#{GEM_DIR}/mock/#{filename}")
        OpenNebula::XMLElement.new(OpenNebula::XMLElement.build_xml(xml, 'VM'))
      end

      context 'vm without RSTIME' do
        let(:filename) { 'one_worker_RSTIME_missing.xml' }

        it 'returns 0' do
          expect(subject.sum_rstime(vm)).to eq(0)
        end
      end

      context 'vm with RSTIME that is 0' do
        let(:filename) { 'one_worker_RSTIME_0.xml' }

        it 'returns 0' do
          expect(subject.sum_rstime(vm)).to eq(0)
        end
      end

      context 'vm without RETIME' do
        let(:filename) { 'one_worker_RETIME_missing.xml' }

        it 'returns 0' do
          expect(subject.sum_rstime(vm)).to eq(0)
        end
      end

      context 'vm with RETIME that is 0' do
        before :example do
          allow(Time).to receive(:now) { 1383741716 }
        end

        let(:filename) { 'one_worker_RETIME_0.xml' }

        it 'returns difference between current time and start of the virtual machine' do
          expect(subject.sum_rstime(vm)).to eq(42)
        end
      end

      context 'vm with RSTIME bigger than RETIME' do
        let(:filename) { 'one_worker_RSTIME_>_RETIME.xml' }

        it 'returns nil' do
          expect(subject.sum_rstime(vm)).to be_nil
        end
      end
    end
  end
end