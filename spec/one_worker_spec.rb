require 'spec_helper'

describe OneWorker do
  subject { one_worker }

  let(:one_worker) { OneWorker.new }
  let(:oda) { double('oda') }

  describe '.common_data' do
    before :example do
      Settings['endpoint'] = 'machine.hogwarts.co.uk'
      Settings['site_name'] = 'Hogwarts'
      Settings['cloud_type'] = 'OpenNebula'
    end

    let(:common_data) { { 'endpoint' => 'machine.hogwarts.co.uk', 'site_name' => 'Hogwarts', 'cloud_type' => 'OpenNebula' } }

    it 'returns data common for every vm in form of hash' do
      expect(subject.common_data).to eq(common_data)
    end
  end

  describe '.create_user_map' do
    it 'returns user map' do
      expect(subject).to receive(:create_map).with(OpenNebula::UserPool, anything, anything) { 'map' }
      expect(subject.create_user_map(oda)).to eq('map')
    end
  end

  describe '.create_image_map' do
    it 'returns image map' do
      expect(subject).to receive(:create_map).with(OpenNebula::ImagePool, anything, anything) { 'map' }
      expect(subject.create_image_map(oda)).to eq('map')
    end
  end

  describe '.create_map' do
    let(:pool_type) { double('pool_type') }
    let(:mapping) { double('mapping') }

    context 'without any error during data retrieval' do
      before :example do
        expect(oda).to receive(:mapping).with(pool_type, mapping)
      end

      it 'returns requested map' do
        subject.create_map(pool_type, mapping, oda)
      end
    end

    context 'with error during data retrieval' do
      before :example do
        expect(oda).to receive(:mapping).and_raise(Errors::ResourceRetrievalError)
      end

      it 'raises an error' do
        expect { subject.create_map(pool_type, mapping, oda) }.to raise_error(RuntimeError)
      end
    end
  end

  describe '.load_vm' do
    context 'without error' do
      before :example do
        expect(oda).to receive(:vm).with(5) { vm }
      end

      let(:vm) { double('vm') }

      it 'returns vm with given ID' do
        expect(subject.load_vm(5, oda)).to eq(vm)
      end
    end

    context 'with error' do
      before :example do
        expect(oda).to receive(:vm).and_raise(Errors::ResourceRetrievalError)
      end

      it 'returns nil' do
        expect(subject.load_vm(5, oda)).to be_nil
      end
    end
  end

  describe '.parse' do
    let(:regex) { /[[:digit:]]+/ }

    context 'with three parameters' do
      context 'if regex matches the value' do
        it 'returns the value' do
          expect(subject.parse('42', regex, '0')).to eq('42')
        end
      end

      context 'if regex does not match the value' do
        it 'it returns substitute' do
          expect(subject.parse('abc', regex, '0')).to eq('0')
        end
      end
    end

    context 'with two parameters' do
      context 'if regex matches the value' do
        it 'returns the value' do
          expect(subject.parse('42', regex)).to eq('42')
        end
      end

      context 'if regex does not match the value' do
        it 'returns "NULL"' do
          expect(subject.parse('abc', regex)).to eq('NULL')
        end
      end
    end
  end

  describe 'write_data' do
    before :example do
      expect(OneWriter).to receive(:new).with(data, output, anything) { ow }
    end

    let(:data) { double('data') }
    let(:output) { double('output') }
    let(:ow) { double('one_writer') }

    context 'without error' do
      before :example do
        expect(ow).to receive(:write)
      end

      it 'calls OneWriter.write with specified data and output directory' do
        subject.write_data(data, output)
      end
    end

    context 'with error' do
      before :example do
        expect(ow).to receive(:write).and_raise(Errors::ResourceRetrievalError)
      end

      it 'raises a RuntimeError' do
        expect { subject.write_data(data, output) }.to raise_error(RuntimeError)
      end
    end
  end

  describe '.process_vm' do
    before :example do
      Settings['endpoint'] = 'machine.hogwarts.co.uk'
      Settings['site_name'] = 'Hogwarts'
      Settings['cloud_type'] = 'OpenNebula'
    end

    let(:vm) do
      xml = File.read("#{GEM_DIR}/mock/#{filename}")
      OpenNebula::XMLElement.new(OpenNebula::XMLElement.build_xml(xml, 'VM'))
    end

    let(:data) do
      data = {}
      data['endpoint'] = 'machine.hogwarts.co.uk'
      data['site_name'] = 'Hogwarts'
      data['cloud_type'] = 'OpenNebula'
      data['vm_uuid'] = '36551'
      data['start_time'] = Time.at(1383741160)
      data['end_time'] = Time.at(1383742270)
      data['machine_name'] = 'one-36551'
      data['user_id'] = '120'
      data['group_id'] = '0'
      data['user_name'] = 'user_name'
      data['fqan'] = 'gname'
      data['status'] = 'completed'
      data['duration'] = '596'
      data['suspend'] = '514'
      data['cpu_count'] = '1'
      data['network_inbound'] = 0
      data['network_outbound'] = 0
      data['memory'] = '1736960'
      data['image_name'] = 'image_name'

      data
    end

    let(:user_map) { { '120' => 'user_name' } }
    let(:image_map) { { '31' => 'image_name' } }

    context 'with valid vm' do
      let(:filename) { 'one_worker_valid_machine.xml' }

      it 'returns correct vm data' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm without STIME' do
      let(:filename) { 'one_worker_STIME_missing.xml' }

      it 'returns nil' do
        expect(subject.process_vm(vm, user_map, image_map)).to be_nil
      end
    end

    context 'vm with STIME that is not a number' do
      let(:filename) { 'one_worker_STIME_nan.xml' }

      it 'returns nil' do
        expect(subject.process_vm(vm, user_map, image_map)).to be_nil
      end
    end

    context 'vm without ETIME' do
      before :example do
        data['end_time'] = 'NULL'
        data['suspend'] = 'NULL'
      end

      let(:filename) { 'one_worker_ETIME_missing.xml' }

      it 'replaces ETIME with "NULL"' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm with ETIME that is not a number' do
      before :example do
        data['end_time'] = 'NULL'
        data['suspend'] = 'NULL'
      end

      let(:filename) { 'one_worker_ETIME_nan.xml' }

      it 'replaces ETIME with "NULL"' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm ETIME that is 0' do
      before :example do
        data['end_time'] = 'NULL'
        data['suspend'] = 'NULL'
      end

      let(:filename) { 'one_worker_ETIME_0.xml' }

      it 'replaces ETIME with "NULL"' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm with STIME bigger than ETIME' do
      let(:filename) { 'one_worker_STIME_>_ETIME.xml' }

      it 'returns nil' do
        expect(subject.process_vm(vm, user_map, image_map)).to be_nil
      end
    end

    context 'vm without DEPLOY_ID' do
      let(:filename) { 'one_worker_DEPLOY_ID_missing.xml' }

      it 'replaces machine name with string created from id and prefix "one-"' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm without UID' do
      before :example do
        data['user_id'] = 'NULL'
        data['user_name'] = 'NULL'
      end

      let(:filename) { 'one_worker_UID_missing.xml' }

      it 'replaces user id with "NULL"' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm without GID' do
      before :example do
        data['group_id'] = 'NULL'
      end

      let(:filename) { 'one_worker_GID_missing.xml' }

      it 'replaces group id with "NULL"' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm without GNAME' do
      before :example do
        data['fqan'] = nil
      end

      let(:filename) { 'one_worker_GNAME_missing.xml' }

      it 'sets fqan to nil' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm without STATE' do
      before :example do
        data['status'] = 'NULL'
      end

      let(:filename) { 'one_worker_STATE_missing.xml' }

      it 'replaces status with "NULL"' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm with STATE with value out of range' do
      before :example do
        data['status'] = 'NULL'
      end

      let(:filename) { 'one_worker_STATE_out_of_range.xml' }

      it 'replaces status with "NULL"' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm without HISTORY_RECORDS' do
      let(:filename) { 'one_worker_HISTORY_RECORDS_missing.xml' }

      it 'returns nil' do
        expect(subject.process_vm(vm, user_map, image_map)).to be_nil
      end
    end

    context 'vm one HISTORY record' do
      let(:filename) { 'one_worker_HISTORY_one.xml' }

      it 'returns correct vm data' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm many HISTORY records' do
      before :example do
        data['duration'] = '831'
        data['suspend'] = '279'
      end

      let(:filename) { 'one_worker_HISTORY_many.xml' }

      it 'returns correct vm data' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm without TEMPLATE' do
      before :example do
        data['cpu_count'] = '1'
        data['image_name'] = 'NULL'
        data['memory'] = '0'
      end

      let(:filename) { 'one_worker_TEMPLATE_missing.xml' }

      it 'replaces items in TEMPLATE section with "NULL"' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm without VCPU' do
      before :example do
        data['cpu_count'] = '1'
      end

      let(:filename) { 'one_worker_VCPU_missing.xml' }

      it 'replaces cpu count with value 1' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm with VCPU that is 0' do
      before :example do
        data['cpu_count'] = '1'
      end

      let(:filename) { 'one_worker_VCPU_0.xml' }

      it 'replaces cpu count with value 1' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm with VCPU that is not a number' do
      before :example do
        data['cpu_count'] = '1'
      end

      let(:filename) { 'one_worker_VCPU_nan.xml' }

      it 'replaces cpu count with value 1' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm without NET_TX' do
      before :example do
        data['network_inbound'] = 0
      end

      let(:filename) { 'one_worker_NET_TX_missing.xml' }

      it 'replaces network outbound with value 0' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm with NET_TX that is 0' do
      before :example do
        data['network_inbound'] = 0
      end

      let(:filename) { 'one_worker_NET_TX_0.xml' }

      it 'replaces network outbound with value 0' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm with NET_TX that is not a number' do
      before :example do
        data['network_inbound'] = 0
      end

      let(:filename) { 'one_worker_NET_TX_nan.xml' }

      it 'replaces network outbound with value 0' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm without NET_RX' do
      before :example do
        data['network_outbound'] = 0
      end

      let(:filename) { 'one_worker_NET_RX_missing.xml' }

      it 'replaces network outbound with value 0' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm with NET_RX that is 0' do
      before :example do
        data['network_outbound'] = 0
      end

      let(:filename) { 'one_worker_NET_RX_0.xml' }

      it 'replaces network outbound with value 0' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm with NET_RX that is not a number' do
      before :example do
        data['network_outbound'] = 0
      end

      let(:filename) { 'one_worker_NET_RX_nan.xml' }

      it 'replaces network outbound with value 0' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm without MEMORY' do
      before :example do
        data['memory'] = '0'
      end

      let(:filename) { 'one_worker_MEMORY_missing.xml' }

      it 'replaces memory with value 0' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm with MEMORY that is 0' do
      before :example do
        data['memory'] = '0'
      end

      let(:filename) { 'one_worker_MEMORY_0.xml' }

      it 'replaces memory with value 0' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm with MEMORY that is not a number' do
      before :example do
        data['memory'] = '0'
      end

      let(:filename) { 'one_worker_MEMORY_nan.xml' }

      it 'replaces memory with value 0' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm without DISK' do
      before :example do
        data['image_name'] = 'NULL'
      end

      let(:filename) { 'one_worker_DISK_missing.xml' }

      it 'replaces image name with "NULL"' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm without IMAGE_ID' do
      before :example do
        data['image_name'] = 'NULL'
      end

      let(:filename) { 'one_worker_IMAGE_ID_missing.xml' }

      it 'replaces image name with "NULL"' do
        expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
      end
    end

    context 'vm with USER_TEMPLATE/OCCI_COMPUTE_MIXINS' do
      let(:filename) { 'one_worker_vm4.xml' }
      let(:image_name) { 'http://occi.localhost/occi/infrastructure/os_tpl#uuid_monitoring_20' }

      it 'w/o map info uses os_tpl mixin' do
        expect(subject.process_vm(vm, user_map, {})['image_name']).to eq(image_name)
      end

      it 'w/ map info uses map info' do
        expect(subject.process_vm(vm, user_map, image_map)['image_name']).to eq(data['image_name'])
      end
    end

    context 'vm with USER_TEMPLATE/OCCI_MIXIN' do
      let(:filename) { 'one_worker_vm5.xml' }
      let(:image_name) { 'https://occi.localhost/occi/infrastructure/os_tpl#omr_worker_x86_64_ide_1_0' }

      it 'w/o map info uses os_tpl mixin' do
        expect(subject.process_vm(vm, user_map, {})['image_name']).to eq(image_name)
      end

      it 'w/ map info uses map info' do
        expect(subject.process_vm(vm, user_map, image_map)['image_name']).to eq(data['image_name'])
      end
    end

    context 'vm with USER_TEMPLATE/USER_X509_DN' do
      let(:filename) { 'one_worker_vm6.xml' }
      let(:user_name) { '/MY=STuPID/CN=DN/CN=HERE' }

      it 'w/o map info uses USER_X509_DN' do
        expect(subject.process_vm(vm, user_map, {})['user_name']).to eq(user_name)
      end

      it 'w/ map info uses USER_X509_DN' do
        expect(subject.process_vm(vm, user_map, image_map)['user_name']).to eq(user_name)
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
      let(:filename) { 'one_worker_RETIME_0.xml' }

      it 'returns 0' do
        expect(subject.sum_rstime(vm)).to eq(0)
      end
    end

    context 'vm with RSTIME bigger than RETIME' do
      let(:filename) { 'one_worker_RSTIME_>_RETIME.xml' }

      it 'returns nil' do
        expect(subject.sum_rstime(vm)).to be_nil
      end
    end
  end

  describe '.perform' do
    before :example do
      allow(OneDataAccessor).to receive(:new) { oda }
      allow(subject).to receive(:create_user_map) { user_map }
      allow(subject).to receive(:create_image_map) { image_map }
      allow(subject).to receive(:load_vm).and_return(:default)
      allow(subject).to receive(:load_vm).with('10', oda).and_return(vm1)
      allow(subject).to receive(:load_vm).with('20', oda).and_return(vm2)
      allow(subject).to receive(:load_vm).with('30', oda).and_return(vm3)
    end

    let(:vms) { '10|20|30' }
    let(:user_map) { { '120' => 'user_name' } }
    let(:image_map) { { '31' => 'image_name' } }
    let(:vm1) do
      xml = File.read("#{GEM_DIR}/mock/one_worker_vm1.xml")
      OpenNebula::XMLElement.new(OpenNebula::XMLElement.build_xml(xml, 'VM'))
    end
    let(:vm2) do
      xml = File.read("#{GEM_DIR}/mock/one_worker_vm2.xml")
      OpenNebula::XMLElement.new(OpenNebula::XMLElement.build_xml(xml, 'VM'))
    end
    let(:vm3) do
      xml = File.read("#{GEM_DIR}/mock/one_worker_vm3.xml")
      OpenNebula::XMLElement.new(OpenNebula::XMLElement.build_xml(xml, 'VM'))
    end

    let(:data) do
      data = {}
      data['endpoint'] = 'machine.hogwarts.co.uk'
      data['site_name'] = 'Hogwarts'
      data['cloud_type'] = 'OpenNebula'
      data['vm_uuid'] = '36551'
      data['start_time'] = Time.at(1383741160)
      data['end_time'] = Time.at(1383742270)
      data['machine_name'] = 'one-36551'
      data['user_id'] = '120'
      data['group_id'] = '0'
      data['user_name'] = 'user_name'
      data['fqan'] = 'gname'
      data['status'] = 'completed'
      data['duration'] = '596'
      data['suspend'] = '514'
      data['cpu_count'] = '1'
      data['network_inbound'] = 0
      data['network_outbound'] = 0
      data['memory'] = '1736960'
      data['image_name'] = 'image_name'

      data
    end

    let(:vm1_data) { data }
    let(:vm2_data) do
      vm2_data = data.clone
      vm2_data['vm_uuid'] = '36552'

      vm2_data
    end
    let(:vm3_data) do
      vm3_data = data.clone
      vm3_data['vm_uuid'] = '36553'

      vm3_data
    end

    context 'with valid vms' do
      it 'writes vm data' do
        expect(subject).to receive(:write_data).with([vm1_data, vm2_data, vm3_data], anything)
        subject.perform(vms, 'output_dir')
      end
    end

    context 'with one vm not loaded correclty' do
      before :example do
        allow(subject).to receive(:load_vm).with('20', oda).and_return(nil)
      end

      it 'writes data of the correct vms' do
        expect(subject).to receive(:write_data).with([vm1_data, vm3_data], anything)
        subject.perform(vms, 'output_dir')
      end
    end

    context 'with one vm that has malformed data' do
      let(:vm2) do
        xml = File.read("#{GEM_DIR}/mock/one_worker_malformed_vm.xml")
        OpenNebula::XMLElement.new(OpenNebula::XMLElement.build_xml(xml, 'VM'))
      end

      it 'writes data of the correct vms' do
        expect(subject).to receive(:write_data).with([vm1_data, vm3_data], anything)
        subject.perform(vms, 'output_dir')
      end
    end
  end
end
