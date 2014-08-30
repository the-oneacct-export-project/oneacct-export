require 'spec_helper'
require 'errors'
require 'logger'

describe OneDataAccessor do
  subject { one_data_accessor }

  before :example do
    Settings.output['num_of_vms_per_file'] = 100
    Settings.xml_rpc['endpoint'] = nil
    Settings.xml_rpc['secret'] = nil
    allow(OpenNebula::Client).to receive(:new) { 'one_client' }
  end

  let(:one_data_accessor) { OneDataAccessor.new(Logger.new('/dev/null')) }

  describe '#new' do
    it 'returns OneDataAccessor object' do
      is_expected.to be_instance_of(OneDataAccessor)
    end

    context 'with logger specified' do
      let(:one_data_accessor) { OneDataAccessor.new('fake_logger') }

      it 'correctly assign logger' do
        expect(subject.log).to eq('fake_logger')
      end
    end

    context 'with no batch size specified in settings' do
      before :example do
        Settings.output['num_of_vms_per_file'] = nil
      end

      it 'returns default value for batch size' do
        expect(subject.batch_size).to eq(500)
      end
    end

    context 'with batch size specified in settings' do
      context 'that is a valid batch size' do
        it 'correctly assign batch size' do
          expect(subject.batch_size).to eq(100)
        end
      end

      context 'that is not a valid batch size' do
        before :example do
          Settings.output['num_of_vms_per_file'] = 'infdf54#!@#'
        end

        let(:one_data_accessor) { nil }

        it 'fails with ArgumentError' do
          expect { OneDataAccessor.new(Logger.new('/dev/null')) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '.initialize_client' do
    let(:one_data_accessor) { OneDataAccessor.new(Logger.new('/dev/null')) }

    context 'with correct arguments' do
      before :example do
        Settings.xml_rpc['secret'] = 'secret'
        Settings.xml_rpc['endpoint'] = 'http://machine.hogworts:1234'
      end

      it 'initializes OpenNebula::Client' do
        expect(OpenNebula::Client).to receive(:new).with('secret', 'http://machine.hogworts:1234')
        subject.initialize_client
      end
    end

    context 'with nil arguments' do
      it 'initializes OpenNebula::Client' do
        expect(OpenNebula::Client).to receive(:new).with(nil, nil)
        subject.initialize_client
      end
    end

    context 'with invalid endpoint' do
      before :example do
        Settings.xml_rpc['endpoint'] = 'ef21!@%^|>'
      end

      it 'fails with ArgumentError' do
        expect { OneDataAccessor.new(Logger.new('/dev/null')) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.check_retval' do
    context 'without error' do
      let(:error) { 'no_error' }

      it 'returns true' do
        expect(subject.check_retval(error, nil)).to eq(true)
      end
    end

    context 'with' do
      context 'authentication error' do
        let(:error) { OpenNebula::Error.new(nil, OpenNebula::Error::EAUTHENTICATION) }

        it 'fails with AuthenticationError' do
          expect { subject.check_retval(error, nil) }.to raise_error(Errors::AuthenticationError)
        end
      end

      context 'authorization error' do
        let(:error) { OpenNebula::Error.new(nil, OpenNebula::Error::EAUTHORIZATION) }

        it 'fails with UserNotAuthorizedError' do
          expect { subject.check_retval(error, nil) }.to raise_error(Errors::UserNotAuthorizedError)
        end
      end

      context 'non existing resource error' do
        let(:error) { OpenNebula::Error.new(nil, OpenNebula::Error::ENO_EXISTS) }

        it 'fails with ResourceNotFoundError' do
          expect { subject.check_retval(error, nil) }.to raise_error(Errors::ResourceNotFoundError)
        end
      end

      context 'resource state  error' do
        let(:error) { OpenNebula::Error.new(nil, OpenNebula::Error::EACTION) }

        it 'fails with ResourceStateError' do
          expect { subject.check_retval(error, nil) }.to raise_error(Errors::ResourceStateError)
        end
      end

      context 'with any of above errors and custom error class' do
        let(:error) { OpenNebula::Error.new(nil, OpenNebula::Error::EACTION) }

        it 'fails with specified error' do
          expect { subject.check_retval(error, Errors::ResourceRetrievalError) }.to raise_error(Errors::ResourceStateError)
        end
      end

      context 'with error not specified above and custom error class' do
        let(:error) { OpenNebula::Error.new(nil, OpenNebula::Error::ENOTDEFINED) }

        it 'fails with customm error' do
          expect { subject.check_retval(error, Errors::ResourceRetrievalError) }.to raise_error(Errors::ResourceRetrievalError)
        end
      end
    end
  end

  describe '.load_vm_pool' do
    before :example do
      allow(vm_pool).to receive(:info) { 'valid_rc' }
      allow(vm_pool).to receive(:to) { vm_pool }
      allow(OpenNebula::VirtualMachinePool).to receive(:new) { vm_pool }
    end

    let(:vm_pool) { double('vm_pool') }

    context 'with valid batch number' do
      it 'requests vms with correct range' do
        expect(vm_pool).to receive(:info).with(OpenNebula::Pool::INFO_ALL, 0, 99, OpenNebula::VirtualMachinePool::INFO_ALL_VM)
        subject.load_vm_pool(0)

        expect(vm_pool).to receive(:info).with(OpenNebula::Pool::INFO_ALL, 100, 199, OpenNebula::VirtualMachinePool::INFO_ALL_VM)
        subject.load_vm_pool(1)

        expect(vm_pool).to receive(:info).with(OpenNebula::Pool::INFO_ALL, 300, 399, OpenNebula::VirtualMachinePool::INFO_ALL_VM)
        subject.load_vm_pool(3)

        expect(vm_pool).to receive(:info).with(OpenNebula::Pool::INFO_ALL, 500, 599, OpenNebula::VirtualMachinePool::INFO_ALL_VM)
        subject.load_vm_pool(5)

        expect(vm_pool).to receive(:info).with(OpenNebula::Pool::INFO_ALL, 1000, 1099, OpenNebula::VirtualMachinePool::INFO_ALL_VM)
        subject.load_vm_pool(10)

        expect(vm_pool).to receive(:info).with(OpenNebula::Pool::INFO_ALL, 1200, 1299, OpenNebula::VirtualMachinePool::INFO_ALL_VM)
        subject.load_vm_pool(12)
      end

      it 'returns obtained vm pool' do
        expect(subject.load_vm_pool(0)).to eq(vm_pool)
      end
    end

    context 'with invalid batch number' do
      it 'fails with ArgumentError' do
        expect { subject.load_vm_pool('invalid_number') }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.vm' do
    before :example do
      allow(vm).to receive(:info) { 'valid_rc' }
      allow(vm).to receive(:to) { vm }
      allow(OpenNebula::VirtualMachine).to receive(:new) { vm }
      allow(OpenNebula::VirtualMachine).to receive(:build_xml)
    end

    let(:vm) { double('vm') }

    context 'with valid vm id' do
      it 'requests correct vm' do
        expect(OpenNebula::VirtualMachine).to receive(:build_xml).with(0)
        subject.vm(0)

        expect(OpenNebula::VirtualMachine).to receive(:build_xml).with(42)
        subject.vm(42)

        expect(OpenNebula::VirtualMachine).to receive(:build_xml).with(123)
        subject.vm(123)
      end

      it 'returns obtained vm' do
        expect(subject.vm(0)).to eq(vm)
      end
    end

    context 'with invalid vm id' do
      it 'fails with ArgumentError' do
        expect { subject.vm('invalid_number') }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.want?' do
    let(:vm) { { 'STATE' => OneDataAccessor::STATE_DONE, 'STIME' => 0, 'ETIME' => 2000, 'GNAME' => 'group1' } }
    let(:range) { { from: 500, to: 1000 } }
    let(:groups) { { include: ['group1'] } }

    context 'with nils for groups and range' do
      it 'returns true' do
        expect(subject.want?(vm, nil, nil)).to eq(true)
      end
    end

    context 'with empty groups and range' do
      it 'returns true' do
        expect(subject.want?(vm, {}, {})).to eq(true)
      end
    end

    context 'with nil vm' do
      it 'returns false' do
        expect(subject.want?(nil, range, groups)).to eq(false)
      end
    end

    context 'with ranges specified' do
      context 'and vm was stopped before the time range' do
        before :example do
          vm['ETIME'] = 100
        end

        it 'returns false' do
          expect(subject.want?(vm, range, groups)).to eq(false)
        end
      end

      context 'and vm was started after the time range' do
        before :example do
          vm['STIME'] = 1500
        end

        it 'returns false' do
          expect(subject.want?(vm, range, groups)).to eq(false)
        end
      end
    end

    context 'with groups specified' do
      context 'and vm was not among included groups' do
        before :example do
          vm['GNAME'] = 'group_not_included'
        end

        it 'returns false' do
          expect(subject.want?(vm, range, groups)).to eq(false)
        end
      end

      context 'and vm was among excluded groups' do
        before :example do
          groups.delete :include
          groups[:exclude] = ['group1']
        end

        it 'returns false' do
          expect(subject.want?(vm, range, groups)).to eq(false)
        end
      end
    end

    context 'with vm within the range and among included groups' do
      it 'returns true' do
        expect(subject.want?(vm, range, groups)).to eq(true)
      end
    end
  end

  describe '.vms' do
    before :example do
      allow(subject).to receive(:load_vm_pool) { vm_pool }
      allow(subject).to receive(:want?) { true }
    end

    let(:vm1) { { 'ID' => '1' } }
    let(:vm2) { { 'ID' => '2' } }
    let(:vm3) { { 'ID' => '3' } }
    let(:vm_pool) { [vm1, vm2, vm3] }
    let(:batch_number) { 5 }

    context 'is called with some batch number' do
      before :example do
        expect(subject).to receive(:load_vm_pool).with(5) { vm_pool }
      end

      it 'calls load_vm_pool with that batch number' do
        subject.vms(batch_number, nil, nil)
      end
    end

    context 'when vm pool is empty' do
      let(:vm_pool) { [] }

      it 'returns nil' do
        expect(subject.vms(batch_number, nil, nil)).to be_nil
      end
    end

    context 'for every vm obtained from vm pool' do
      before :example do
        expect(subject).to receive(:want?).with(vm1, nil, nil).once
        expect(subject).to receive(:want?).with(vm2, nil, nil).once
        expect(subject).to receive(:want?).with(vm3, nil, nil).once
      end
      it 'calls want?' do
        subject.vms(batch_number, nil, nil)
      end
    end

    context 'for every vm obtained from vm pool' do
      context 'with ID attribute' do
        it 'returns ID of those vms' do
          expect(subject.vms(batch_number, nil, nil)).to eq([1, 2, 3])
        end
      end

      context 'with vms with missing ID attribute' do
        let(:vm1) { {} }
        let(:vm3) { {} }

        it 'skips vms without ID attribute and returns only thouse with it' do
          expect(subject.vms(batch_number, nil, nil)).to eq([2])
        end
      end
    end
  end

  describe '.mapping' do
    before :example do
      allow(pool_class).to receive(:new) { pool }
      allow(pool).to receive(:respond_to?).and_call_original
      allow(pool).to receive(:respond_to?).with('info_all') { true }
      allow(pool).to receive(:info_all) { 'valid_rc' }
      allow(pool).to receive(:info) { 'valid_rc' }
    end

    let(:pool_class) { double('pool_class') }
    let(:vm1) { { 'ID' => '1', 'XPATH' => 'data1' } }
    let(:vm2) { { 'ID' => '2', 'XPATH' => 'data2' } }
    let(:vm3) { { 'ID' => '3', 'XPATH' => 'data3' } }
    let(:pool) { [vm1, vm2, vm3] }
    let(:xpath) { 'XPATH' }
    let(:result) { { '1' => 'data1', '2' => 'data2', '3' => 'data3' } }

    context 'with pool class that has info_all method' do
      before :example do
        expect(pool).to receive(:info_all)
      end

      it 'calls info_all method for that pool class' do
        subject.mapping(pool_class, xpath)
      end
    end

    context 'with pool class that does not have info_all method' do
      before :example do
        allow(pool).to receive(:respond_to?).with('info_all') { false }
        expect(pool).to receive(:info)
      end

      it 'calls info method for that pool class' do
        subject.mapping(pool_class, xpath)
      end
    end

    context 'for every item obtained from the pool' do
      context 'where every item has an ID' do
        it 'creates a mapping of item\'s ID and its element according to xpath' do
          expect(subject.mapping(pool_class, xpath)).to eq(result)
        end
      end

      context 'where some items miss ID attribute' do
        let(:vm1) { {} }
        let(:vm3) { {} }
        let(:result) { { '2' => 'data2' } }

        it 'creates a mapping of item\'s ID and its element according to xpath, skipping items without ID' do
          expect(subject.mapping(pool_class, xpath)).to eq(result)
        end
      end
    end
  end
end
