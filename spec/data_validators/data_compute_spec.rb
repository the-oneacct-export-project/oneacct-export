require 'spec_helper'

module DataValidators
  describe DataCompute do
    subject { data_compute }

    let(:data_compute) do
      data_compute = Object.new
      data_compute.extend(Errors)
      data_compute.extend(InputValidator)
      data_compute.extend(DataValidatorHelper)
      data_compute.extend(DataCompute)

      data_compute
    end

    let(:log) { double('log') }

    before :example do
      allow(subject).to receive(:log).and_return(log)
      allow(log).to receive(:warn)
    end

    describe '.sum_disk_size' do
      let(:disks) do
        disks = []
        disk = {'size' => '10240'}
        disks << disk
        disk = {'size' => '42368'}
        disks << disk

        disks
      end

      let(:vm_id) { 42 }

      context 'vm without disks' do
        it 'returns nil' do
          expect(subject.sum_disk_size(nil, vm_id)).to be_nil
        end
      end

      context 'vm empty disks' do
        it 'returns 0' do
          expect(subject.sum_disk_size([], vm_id)).to eq(0)
        end
      end

      context 'vm with disk without size' do
        before :example do
          disks[0] = {}
        end

        it 'returns nil' do
          expect(subject.sum_disk_size(disks, vm_id)).to be_nil
        end
      end

      context 'vm with disk with invalid size' do
        before :example do
          disks[0] = {'size' => 'not_a_number'}
        end

        it 'returns nil' do
          expect(subject.sum_disk_size(disks, vm_id)).to be_nil
        end
      end

      context 'vm with single disk and valid size' do
        it 'return correct disk size' do
          expect(subject.sum_disk_size(disks[1..1], vm_id)).to eq(42368)
        end
      end

      context 'vm with multiple disks and valid size' do
        it 'return correct disk size' do
          expect(subject.sum_disk_size(disks, vm_id)).to eq(52608)
        end
      end
    end

    describe '.sum_rstime' do

      let(:history) do
        history = []
        rec = {}
        rec['start_time'] = '1383741169'
        rec['end_time'] = '1383741259'
        rec['rstart_time'] = '1383741278'
        rec['rend_time'] = '1383741367'
        rec['seq'] = '0'
        rec['hostname'] = 'supermachine1.somewhere.com'
        history << rec
        rec = {}
        rec['start_time'] = '1383741589'
        rec['end_time'] = '1383742270'
        rec['rstart_time'] = '1383741674'
        rec['rend_time'] = '1383742270'
        rec['seq'] = '1'
        rec['hostname'] = 'supermachine2.somewhere.com'
        history << rec

        history
      end

      let(:vm_id) { 42 }
      let(:completed) { true }

      context 'vm without history records' do
        it 'returns nil' do
          expect(subject.sum_rstime(nil, completed, vm_id)).to be_nil
        end
      end

      context 'vm with empty history records' do
        it 'returns 0' do
          expect(subject.sum_rstime([], completed, vm_id)).to eq(0)
        end
      end

      context 'vm without rstart_time' do
        before :example do
          history[0]['rstart_time'] = nil
        end

        it 'skips invalid history record and count the rest' do
          expect(subject.sum_rstime(history, completed, vm_id)).to eq(596)
        end
      end

      context 'vm with rstart_time that is 0' do
        before :example do
          history[0]['rstart_time'] = '0'
        end

        it 'skips invalid history record and count the rest' do
          expect(subject.sum_rstime(history, completed, vm_id)).to eq(596)
        end
      end

      context 'vm without rend_time' do
        before :example do
          history[0]['rend_time'] = nil
        end

        it 'skips invalid history record and count the rest' do
          expect(subject.sum_rstime(history, completed, vm_id)).to eq(596)
        end
      end

      context 'vm with rend_time that is 0' do
        before :example do
          history[0]['rend_time'] = '0'
        end

        context 'and running' do
          before :example do
            allow(Time).to receive(:now) { 1383741716 }
          end

          let(:completed) { false }

          it 'returns difference between current time and start of the virtual machine and count the rest' do
            expect(subject.sum_rstime(history, completed, vm_id)).to eq(1034)
          end
        end

        context 'and stopped' do
          it 'fails with ValidationError' do
            expect { subject.sum_rstime(history, completed, vm_id) }.to raise_error(Errors::ValidationError)
          end
        end
      end

      context 'vm with rstart_time bigger than rend_time' do
        before :example do
          history[0]['rstart_time'] = '1383741259'
          history[0]['rend_time'] = '1383741169'
        end

        it 'fails with ValidationError' do
          expect { subject.sum_rstime(history, completed, vm_id) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with all data valid' do
        it 'count the correct value' do
          expect(subject.sum_rstime(history, completed, vm_id)).to eq(685)
        end
      end
    end
  end
end