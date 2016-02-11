require 'spec_helper'

describe OneWorker do
  subject { one_worker }

  let(:one_worker) { OneWorker.new }
  let(:oda) { double('oda') }

  describe '.output_type_specific_data' do
    context 'with output type apel' do
      before :example do
        Settings.output['output_type'] = 'apel-0.2'
        Settings.output.apel['endpoint'] = 'machine.hogwarts.co.uk'
        Settings.output.apel['site_name'] = 'Hogwarts'
        Settings.output.apel['cloud_type'] = 'OpenNebula'
        Settings.output.apel['cloud_compute_service'] = 'CloudComputeServiceValue'
      end

      let(:output_type_specific_data) { {'endpoint' => 'machine.hogwarts.co.uk', 'site_name' => 'Hogwarts', 'cloud_type' => 'OpenNebula', 'cloud_compute_service' => 'CloudComputeServiceValue'} }

      it 'returns data specific for apel output type in form of hash' do
        expect(subject.output_type_specific_data).to eq(output_type_specific_data)
      end
    end

    context 'with output type pbs' do
      before :example do
        Settings.output['output_type'] = 'pbs-0.1'
        Settings.output.pbs['realm'] = 'REALM'
        Settings.output.pbs['queue'] = 'cloud'
        Settings.output.pbs['scratch_type'] = 'local'
        Settings.output.pbs['host_identifier'] = 'on_localhost'
      end

      let(:output_type_specific_data) { {'realm' => 'REALM', 'pbs_queue' => 'cloud', 'scratch_type' => 'local', 'host' => 'on_localhost'} }

      it 'returns data specific for pbs output type in form of hash' do
        expect(subject.output_type_specific_data).to eq(output_type_specific_data)
      end
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

  describe '.create_cluster_map' do
    it 'returns cluster map' do
      expect(subject).to receive(:create_map).with(OpenNebula::ClusterPool, anything, anything) { 'map' }
      expect(subject.create_cluster_map(oda)).to eq('map')
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

  describe 'process_vm' do
    before :example do
      Settings.output['output_type'] = 'apel-0.2'
      Settings.output.apel['endpoint'] = 'machine.hogwarts.co.uk'
      Settings.output.apel['site_name'] = 'site-name-from-config'
      Settings.output.apel['cloud_type'] = 'OpenNebula'
      Settings.output.apel['cloud_compute_service'] = nil

      allow(vm).to receive(:state_str) { 'DONE' }
    end

    let(:vm) do
      xml = File.read("#{GEM_DIR}/mock/#{filename}")
      OpenNebula::XMLElement.new(OpenNebula::XMLElement.build_xml(xml, 'VM'))
    end

    let(:data) do
      data = {}

      data['endpoint'] = 'machine.hogwarts.co.uk'
      data['site_name'] = 'site-name-from-cluster'
      data['cloud_type'] = 'OpenNebula'
      data['cloud_compute_service'] = nil

      data['vm_uuid'] = '36551'
      data['start_time'] = '1383741160'
      data['end_time'] = '1383742270'
      data['machine_name'] = 'one-36551'
      data['user_id'] = '120'
      data['group_id'] = '0'
      data['user_name'] = 'uname'
      data['group_name'] = 'gname'
      data['status_code'] = '6'
      data['status'] = 'DONE'
      data['cpu_count'] = '1'
      data['network_inbound'] = '43557888'
      data['network_outbound'] = '376832'
      data['memory'] = '1736960'
      data['number_of_public_ips'] = 1
      history = []
      rec = {}
      rec['start_time'] = '1383741169'
      rec['end_time'] = '1383741259'
      rec['rstart_time'] = '0'
      rec['rend_time'] = '0'
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
      data['history'] = history
      data['disks'] = [{'size' => '10240'}, {'size' => '42368'}]

      data['user_dn'] = '/Dn=FrOm/CN=DN/CN=TeMpLaTe'
      data['image_name'] = 'https://appdb.egi.eu/store/vo/image/image_name_from_VMCATCHER_EVENT_AD_MPURI_tag/'

      data['benchmark_type'] = nil
      data['benchmark_value'] = nil

      data['oneacct_export_version'] = ::OneacctExporter::VERSION

      data
    end

    let(:user_map) { {'120' => '/Dn=FrOm/CN=DN/CN=MaP'} }
    let(:image_map) { {'31' => 'image_name_from_map'} }
    let(:cluster_map) { {'100' => 'site-name-from-cluster'}}
    let(:benchmark_map) { {'123' => nil}  }

    context 'with apel specific data' do
      let(:filename) { 'one_worker_vm_dn01.xml' }

      it 'returns correct vm data with apel specific data' do
        expect(subject.process_vm(vm, user_map, image_map, cluster_map, benchmark_map)).to eq(data)
      end
    end

    context 'with pbs specific data' do
      before :example do
        Settings.output['output_type'] = 'pbs-0.1'
        Settings.output.pbs['realm'] = 'REALM'
        Settings.output.pbs['queue'] = 'cloud'
        Settings.output.pbs['scratch_type'] = 'local'
        Settings.output.pbs['host_identifier'] = 'on_localhost'

        data['realm'] = 'REALM'
        data['pbs_queue'] = 'cloud'
        data['scratch_type'] = 'local'
        data['host'] = 'on_localhost'

        data.delete 'endpoint'
        data.delete 'cloud_type'
        data.delete 'cloud_compute_service'
      end

      let(:filename) { 'one_worker_vm_dn01.xml' }

      it 'returns correct vm data with pbs specific data' do
        expect(subject.process_vm(vm, user_map, image_map, cluster_map, benchmark_map)).to eq(data)
      end
    end

    context 'with user\'s dn in template' do
      let(:filename) { 'one_worker_vm_dn01.xml' }

      it 'returns correct vm data with user\'s dn from template' do
        expect(subject.process_vm(vm, user_map, image_map, cluster_map, benchmark_map)).to eq(data)
      end
    end

    context 'with user\'s dn in map' do
      let(:filename) { 'one_worker_vm_dn02.xml' }

      before :example do
        data['user_dn'] = '/Dn=FrOm/CN=DN/CN=MaP'
      end

      it 'returns correct vm data with user\'s dn from map' do
        expect(subject.process_vm(vm, user_map, image_map, cluster_map, benchmark_map)).to eq(data)
      end
    end

    context 'with image name in VMCATCHER_EVENT_AD_MPURI tag' do
      let(:filename) { 'one_worker_vm_image_name01.xml' }

      it 'returns correct vm data with image name from VMCATCHER_EVENT_AD_MPURI tag' do
        expect(subject.process_vm(vm, user_map, image_map, cluster_map, benchmark_map)).to eq(data)
      end
    end

    context 'with image name in map' do
      let(:filename) { 'one_worker_vm_image_name02.xml' }

      before :example do
        data['image_name'] = 'image_name_from_map'
      end

      it 'returns correct vm data with image name from map' do
        expect(subject.process_vm(vm, user_map, image_map, cluster_map, benchmark_map)).to eq(data)
      end
    end

    #TODO should be moved into tests for mixin method
    context 'with image name in USER_TEMPLATE/OCCI_COMPUTE_MIXINS tag' do
      let(:filename) { 'one_worker_vm_image_name03.xml' }

      before :example do
        data['image_name'] = 'http://occi.localhost/occi/infrastructure/os_tpl#image_name_from_USER_TEMPLATE_OCCI_COMPUTE_MIXINS'
      end

      it 'returns correct vm data with image name from USER_TEMPLATE/OCCI_COMPUTE_MIXINS tag' do
        expect(subject.process_vm(vm, user_map, image_map, cluster_map, benchmark_map)).to eq(data)
      end
    end

    #TODO should be moved into tests for mixin method
    context 'with image name in USER_TEMPLATE/OCCI_MIXIN tag' do
      let(:filename) { 'one_worker_vm_image_name04.xml' }

      before :example do
        data['image_name'] = 'http://occi.localhost/occi/infrastructure/os_tpl#image_name_from_USER_TEMPLATE_OCCI_MIXIN'
      end

      it 'returns correct vm data with image name from USER_TEMPLATE/OCCI_MIXIN tag' do
        expect(subject.process_vm(vm, user_map, image_map, cluster_map, benchmark_map)).to eq(data)
      end
    end

    #TODO should be moved into tests for mixin method
    context 'with image name in TEMPLATE/OCCI_MIXIN tag' do
      let(:filename) { 'one_worker_vm_image_name05.xml' }

      before :example do
        data['image_name'] = 'http://occi.localhost/occi/infrastructure/os_tpl#image_name_from_TEMPLATE_OCCI_MIXIN'
      end

      it 'returns correct vm data with image name from TEMPLATE/OCCI_MIXIN tag' do
        expect(subject.process_vm(vm, user_map, image_map, cluster_map, benchmark_map)).to eq(data)
      end
    end

    context 'with image name as image id' do
      let(:filename) { 'one_worker_vm_image_name06.xml' }

      before :example do
        data['image_name'] = '42'
      end

      it 'returns correct vm data with image name as image id' do
        expect(subject.process_vm(vm, user_map, image_map, cluster_map, benchmark_map)).to eq(data)
      end
    end

    context 'without site-name on cluster (APEL)' do
      let(:filename) { 'one_worker_vm_dn01.xml' }
      let(:cluster_map) { {} }

      before :example do
        data['site_name'] = 'site-name-from-config'
      end

      it 'returns correct vm data with site-name from configuration file' do
        expect(subject.process_vm(vm, user_map, image_map, cluster_map, benchmark_map)).to eq(data)
      end
    end

    context 'without site-name on cluster (NON APEL)' do
      let(:filename) { 'one_worker_vm_dn01.xml' }
      let(:cluster_map) { {} }

      before :example do
        Settings.output['output_type'] = 'pbs-0.1'
        Settings.output.pbs['realm'] = 'REALM'
        Settings.output.pbs['queue'] = 'cloud'
        Settings.output.pbs['scratch_type'] = 'local'
        Settings.output.pbs['host_identifier'] = 'on_localhost'

        data['realm'] = 'REALM'
        data['pbs_queue'] = 'cloud'
        data['scratch_type'] = 'local'
        data['host'] = 'on_localhost'

        data.delete 'endpoint'
        data.delete 'cloud_type'
        data.delete 'cloud_compute_service'
        data.delete 'site_name'
      end

      it 'returns correct vm data without any site-name' do
        expect(subject.process_vm(vm, user_map, image_map, cluster_map, benchmark_map)).to eq(data)
      end
    end
  end

  describe 'history_records' do
    let(:vm) do
      xml = File.read("#{GEM_DIR}/mock/#{filename}")
      OpenNebula::XMLElement.new(OpenNebula::XMLElement.build_xml(xml, 'VM'))
    end

    let(:history) do
      history = []
      rec = {}
      rec['start_time'] = '1383741169'
      rec['end_time'] = '1383741259'
      rec['rstart_time'] = '0'
      rec['rend_time'] = '0'
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

    context 'with correct history records in vm' do
      let(:filename) { 'one_worker_vm_dn01.xml' }

      it 'returns history records for vm' do
        expect(subject.history_records(vm)).to eq(history)
      end
    end

    context 'with no history records' do
      let(:filename) { 'one_worker_vm_empty_history_records.xml' }

      it 'returns emtpy array' do
        expect(subject.history_records(vm)).to be_empty
      end
    end
  end

  describe 'disk_records' do
    let(:vm) do
      xml = File.read("#{GEM_DIR}/mock/#{filename}")
      OpenNebula::XMLElement.new(OpenNebula::XMLElement.build_xml(xml, 'VM'))
    end

    let(:disks) do
      disks = []
      disk = {}
      disk['size'] = '10240'
      disks << disk
      disk = {}
      disk['size'] = '42368'
      disks << disk

      disks
    end

    context 'with correct disk records in vm' do
      let(:filename) { 'one_worker_vm_dn01.xml' }

      it 'returns history records for vm' do
        expect(subject.disk_records(vm)).to eq(disks)
      end
    end

    context 'with no disk records' do
      let(:filename) { 'one_worker_vm_empty_disk_records.xml' }

      it 'returns emtpy array' do
        expect(subject.disk_records(vm)).to be_empty
      end
    end
  end

  describe ".number_of_public_ips" do
    let(:vm) do
      xml = File.read("#{GEM_DIR}/mock/#{filename}")
      OpenNebula::XMLElement.new(OpenNebula::XMLElement.build_xml(xml, 'VM'))
    end

    context "with multiple NICs (multiple IPs with duplicates) " do
      let(:filename) { 'one_worker_vm_number_of_public_ips_01.xml' }
      it "returns the correct number of public IPs" do
        expect(subject.number_of_public_ips(vm)).to eq 8
      end
    end
    context "with no NICs" do
      let(:filename) { 'one_worker_vm_number_of_public_ips_02.xml' }
      it "returns 0, the correct number of IPs" do
        expect(subject.number_of_public_ips(vm)).to eq 0
      end
    end
    context "with single NIC (multiple IPs with duplicates)" do
      let(:filename) { 'one_worker_vm_number_of_public_ips_03.xml' }
      it "returns the correct number of public IPs" do
        expect(subject.number_of_public_ips(vm)).to eq 8
      end
    end
  end

  describe '.perform' do
    before :example do
      Settings.output['output_type'] = 'unknown'
      allow(OneDataAccessor).to receive(:new) { oda }
      allow(subject).to receive(:create_user_map) { 'user_map' }
      allow(subject).to receive(:create_image_map) { 'image_map' }
      allow(subject).to receive(:create_cluster_map) { 'cluster_map' }
      allow(oda).to receive(:benchmark_map) { 'benchmark_map' }
      allow(subject).to receive(:load_vm).with('10', oda).and_return('10')
      allow(subject).to receive(:load_vm).with('20', oda).and_return('20')
      allow(subject).to receive(:load_vm).with('30', oda).and_return('30')
      allow(subject).to receive(:process_vm).with('10', anything, anything, anything, anything).and_return('data_vm1')
      allow(subject).to receive(:process_vm).with('20', anything, anything, anything, anything).and_return('data_vm2')
      allow(subject).to receive(:process_vm).with('30', anything, anything, anything, anything).and_return('data_vm3')
    end

    let(:vms) { '10|20|30' }
    let(:file_number) { 42 }

    context 'with valid vms' do
      it 'writes vm data' do
        expect(subject).to receive(:write_data).with(['data_vm1', 'data_vm2', 'data_vm3'], file_number)
        subject.perform(vms, file_number)
      end
    end

    context 'with one vm not loaded correctly' do
      before :example do
        allow(subject).to receive(:load_vm).with('20', oda).and_return(nil)
      end

      it 'writes data of the correct vms' do
        expect(subject).to receive(:write_data).with(['data_vm1', 'data_vm3'], file_number)
        subject.perform(vms, file_number)
      end
    end

    context 'with apel data validator' do
      before :example do
        Settings.output['output_type'] = 'apel-0.2'
      end

      let(:validator) { double('validator') }

      context 'and all vm valid' do
        it 'uses apel data validator to validate all vms and all passes' do
          expect(DataValidators::ApelDataValidator).to receive(:new).and_return(validator).exactly(3).times
          expect(validator).to receive(:validate_data).with('data_vm1').and_return('valid_data_vm1')
          expect(validator).to receive(:validate_data).with('data_vm2').and_return('valid_data_vm2')
          expect(validator).to receive(:validate_data).with('data_vm3').and_return('valid_data_vm3')
          expect(subject).to receive(:write_data).with(['valid_data_vm1', 'valid_data_vm2', 'valid_data_vm3'], file_number)
          subject.perform(vms, file_number)
        end
      end

      context 'and all vm valid but one' do
        it 'uses apel data validator to validate all vms and all but one passes' do
          expect(DataValidators::ApelDataValidator).to receive(:new).and_return(validator).exactly(3).times
          expect(validator).to receive(:validate_data).with('data_vm1').and_return('valid_data_vm1')
          expect(validator).to receive(:validate_data).with('data_vm2').and_raise(Errors::ValidationError)
          expect(validator).to receive(:validate_data).with('data_vm3').and_return('valid_data_vm3')
          expect(subject).to receive(:write_data).with(['valid_data_vm1', 'valid_data_vm3'], file_number)
          subject.perform(vms, file_number)
        end
      end
    end

    context 'with apel data validator' do
      before :example do
        Settings.output['output_type'] = 'pbs-0.1'
      end

      let(:validator) { double('validator') }

      context 'and all vm valid' do
        it 'uses apel data validator to validate all vms and all passes' do
          expect(DataValidators::PbsDataValidator).to receive(:new).and_return(validator).exactly(3).times
          expect(validator).to receive(:validate_data).with('data_vm1').and_return('valid_data_vm1')
          expect(validator).to receive(:validate_data).with('data_vm2').and_return('valid_data_vm2')
          expect(validator).to receive(:validate_data).with('data_vm3').and_return('valid_data_vm3')
          expect(subject).to receive(:write_data).with(['valid_data_vm1', 'valid_data_vm2', 'valid_data_vm3'], file_number)
          subject.perform(vms, file_number)
        end
      end

      context 'and all vm valid but one' do
        it 'uses apel data validator to validate all vms and all but one passes' do
          expect(DataValidators::PbsDataValidator).to receive(:new).and_return(validator).exactly(3).times
          expect(validator).to receive(:validate_data).with('data_vm1').and_return('valid_data_vm1')
          expect(validator).to receive(:validate_data).with('data_vm2').and_raise(Errors::ValidationError)
          expect(validator).to receive(:validate_data).with('data_vm3').and_return('valid_data_vm3')
          expect(subject).to receive(:write_data).with(['valid_data_vm1', 'valid_data_vm3'], file_number)
          subject.perform(vms, file_number)
        end
      end
    end
  end

  describe '.search_benchmark' do
    let(:vm) do
      xml = File.read("#{GEM_DIR}/mock/#{filename}")
      OpenNebula::XMLElement.new(OpenNebula::XMLElement.build_xml(xml, 'VM'))
    end

    let(:benchmark_map) do
      values1 = { :benchmark_type => 'bench_type_1', :mixins => { 'mixin1' => '34.12' } }
      values2 = { :benchmark_type => 'bench_type_2', :mixins => { 'mixin2' => '123.2', 'mixin3' => '129.6' } }
      values3 = { }

      benchmark_map = { '19' => values1, '11' => values2, '23' => values3 }
      benchmark_map
    end

    context 'with empty benchmark_map' do
      let(:filename) { 'one_worker_vm_search_benchmark_01.xml' }
      let(:benchmark_map) { {} }
      let(:expected) { { :benchmark_type => nil, :benchmark_value => nil } }

      it 'returns array with two nil items' do
        expect(subject.search_benchmark(vm, benchmark_map)).to eq(expected)
      end
    end

    context 'with no data for the virtual machine in benchmark_map' do
      let(:filename) { 'one_worker_vm_search_benchmark_02.xml' }
      let(:expected) { { :benchmark_type => nil, :benchmark_value => nil } }

      it 'returns array with two nil items' do
        expect(subject.search_benchmark(vm, benchmark_map)).to eq(expected)
      end
    end

    context 'with correct data in vm and benchmark_map' do
      let(:filename) { 'one_worker_vm_search_benchmark_01.xml' }
      let(:expected) { { :benchmark_type => 'bench_type_2', :benchmark_value => '129.6' } }

      it 'returns correct benchmark type and value' do
        expect(subject.search_benchmark(vm, benchmark_map)).to eq(expected)
      end
    end
  end

end
