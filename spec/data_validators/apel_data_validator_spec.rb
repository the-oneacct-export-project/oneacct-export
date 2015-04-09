require 'spec_helper'

module DataValidators
  describe ApelDataValidator do


  end
end

# describe '.process_vm' do
#   before :example do
#     Settings['endpoint'] = 'machine.hogwarts.co.uk'
#     Settings['site_name'] = 'Hogwarts'
#     Settings['cloud_type'] = 'OpenNebula'
#   end
#
#   let(:vm) do
#     xml = File.read("#{GEM_DIR}/mock/#{filename}")
#     OpenNebula::XMLElement.new(OpenNebula::XMLElement.build_xml(xml, 'VM'))
#   end
#
#   let(:data) do
#     data = {}
#     data['endpoint'] = 'machine.hogwarts.co.uk'
#     data['site_name'] = 'Hogwarts'
#     data['cloud_type'] = 'OpenNebula'
#     data['vm_uuid'] = '36551'
#     data['start_time'] = Time.at(1383741160)
#     data['end_time'] = Time.at(1383742270)
#     data['machine_name'] = 'one-36551'
#     data['user_id'] = '120'
#     data['group_id'] = '0'
#     data['user_name'] = 'user_name'
#     data['fqan'] = 'gname'
#     data['status'] = 'completed'
#     data['duration'] = '596'
#     data['suspend'] = '514'
#     data['cpu_count'] = '1'
#     data['network_inbound'] = 0
#     data['network_outbound'] = 0
#     data['memory'] = '1736960'
#     data['image_name'] = 'image_name'
#     data['disk_size'] = 'NULL'
#
#     data
#   end
#
#   let(:user_map) { { '120' => 'user_name' } }
#   let(:image_map) { { '31' => 'image_name' } }
#
#   context 'with valid vm' do
#     let(:filename) { 'one_worker_valid_machine.xml' }
#
#     it 'returns correct vm data' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm without STIME' do
#     let(:filename) { 'one_worker_STIME_missing.xml' }
#
#     it 'returns nil' do
#       expect(subject.process_vm(vm, user_map, image_map)).to be_nil
#     end
#   end
#
#   context 'vm with STIME that is not a number' do
#     let(:filename) { 'one_worker_STIME_nan.xml' }
#
#     it 'returns nil' do
#       expect(subject.process_vm(vm, user_map, image_map)).to be_nil
#     end
#   end
#
#   context 'vm without ETIME' do
#     before :example do
#       data['end_time'] = 'NULL'
#       data['suspend'] = 'NULL'
#     end
#
#     let(:filename) { 'one_worker_ETIME_missing.xml' }
#
#     it 'replaces ETIME with "NULL"' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm with ETIME that is not a number' do
#     before :example do
#       data['end_time'] = 'NULL'
#       data['suspend'] = 'NULL'
#     end
#
#     let(:filename) { 'one_worker_ETIME_nan.xml' }
#
#     it 'replaces ETIME with "NULL"' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm ETIME that is 0' do
#     before :example do
#       data['end_time'] = 'NULL'
#       data['suspend'] = 'NULL'
#     end
#
#     let(:filename) { 'one_worker_ETIME_0.xml' }
#
#     it 'replaces ETIME with "NULL"' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm with STIME bigger than ETIME' do
#     let(:filename) { 'one_worker_STIME_>_ETIME.xml' }
#
#     it 'returns nil' do
#       expect(subject.process_vm(vm, user_map, image_map)).to be_nil
#     end
#   end
#
#   context 'vm without DEPLOY_ID' do
#     let(:filename) { 'one_worker_DEPLOY_ID_missing.xml' }
#
#     it 'replaces machine name with string created from id and prefix "one-"' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm without UID' do
#     before :example do
#       data['user_id'] = 'NULL'
#       data['user_name'] = 'NULL'
#     end
#
#     let(:filename) { 'one_worker_UID_missing.xml' }
#
#     it 'replaces user id with "NULL"' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm without GID' do
#     before :example do
#       data['group_id'] = 'NULL'
#     end
#
#     let(:filename) { 'one_worker_GID_missing.xml' }
#
#     it 'replaces group id with "NULL"' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm without GNAME' do
#     before :example do
#       data['fqan'] = nil
#     end
#
#     let(:filename) { 'one_worker_GNAME_missing.xml' }
#
#     it 'sets fqan to nil' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm without STATE' do
#     before :example do
#       data['status'] = 'NULL'
#     end
#
#     let(:filename) { 'one_worker_STATE_missing.xml' }
#
#     it 'replaces status with "NULL"' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm with STATE with value out of range' do
#     before :example do
#       data['status'] = 'NULL'
#     end
#
#     let(:filename) { 'one_worker_STATE_out_of_range.xml' }
#
#     it 'replaces status with "NULL"' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm without HISTORY_RECORDS' do
#     let(:filename) { 'one_worker_HISTORY_RECORDS_missing.xml' }
#
#     it 'returns nil' do
#       expect(subject.process_vm(vm, user_map, image_map)).to be_nil
#     end
#   end
#
#   context 'vm one HISTORY record' do
#     let(:filename) { 'one_worker_HISTORY_one.xml' }
#
#     it 'returns correct vm data' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm many HISTORY records' do
#     before :example do
#       data['duration'] = '831'
#       data['suspend'] = '279'
#     end
#
#     let(:filename) { 'one_worker_HISTORY_many.xml' }
#
#     it 'returns correct vm data' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm without TEMPLATE' do
#     before :example do
#       data['cpu_count'] = '1'
#       data['image_name'] = 'NULL'
#       data['memory'] = '0'
#     end
#
#     let(:filename) { 'one_worker_TEMPLATE_missing.xml' }
#
#     it 'replaces items in TEMPLATE section with "NULL"' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm without VCPU' do
#     before :example do
#       data['cpu_count'] = '1'
#     end
#
#     let(:filename) { 'one_worker_VCPU_missing.xml' }
#
#     it 'replaces cpu count with value 1' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm with VCPU that is 0' do
#     before :example do
#       data['cpu_count'] = '1'
#     end
#
#     let(:filename) { 'one_worker_VCPU_0.xml' }
#
#     it 'replaces cpu count with value 1' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm with VCPU that is not a number' do
#     before :example do
#       data['cpu_count'] = '1'
#     end
#
#     let(:filename) { 'one_worker_VCPU_nan.xml' }
#
#     it 'replaces cpu count with value 1' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm without NET_TX' do
#     before :example do
#       data['network_inbound'] = 0
#     end
#
#     let(:filename) { 'one_worker_NET_TX_missing.xml' }
#
#     it 'replaces network outbound with value 0' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm with NET_TX that is 0' do
#     before :example do
#       data['network_inbound'] = 0
#     end
#
#     let(:filename) { 'one_worker_NET_TX_0.xml' }
#
#     it 'replaces network outbound with value 0' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm with NET_TX that is not a number' do
#     before :example do
#       data['network_inbound'] = 0
#     end
#
#     let(:filename) { 'one_worker_NET_TX_nan.xml' }
#
#     it 'replaces network outbound with value 0' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm without NET_RX' do
#     before :example do
#       data['network_outbound'] = 0
#     end
#
#     let(:filename) { 'one_worker_NET_RX_missing.xml' }
#
#     it 'replaces network outbound with value 0' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm with NET_RX that is 0' do
#     before :example do
#       data['network_outbound'] = 0
#     end
#
#     let(:filename) { 'one_worker_NET_RX_0.xml' }
#
#     it 'replaces network outbound with value 0' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm with NET_RX that is not a number' do
#     before :example do
#       data['network_outbound'] = 0
#     end
#
#     let(:filename) { 'one_worker_NET_RX_nan.xml' }
#
#     it 'replaces network outbound with value 0' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm without MEMORY' do
#     before :example do
#       data['memory'] = '0'
#     end
#
#     let(:filename) { 'one_worker_MEMORY_missing.xml' }
#
#     it 'replaces memory with value 0' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm with MEMORY that is 0' do
#     before :example do
#       data['memory'] = '0'
#     end
#
#     let(:filename) { 'one_worker_MEMORY_0.xml' }
#
#     it 'replaces memory with value 0' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm with MEMORY that is not a number' do
#     before :example do
#       data['memory'] = '0'
#     end
#
#     let(:filename) { 'one_worker_MEMORY_nan.xml' }
#
#     it 'replaces memory with value 0' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm without DISK' do
#     before :example do
#       data['image_name'] = 'NULL'
#     end
#
#     let(:filename) { 'one_worker_DISK_missing.xml' }
#
#     it 'replaces image name with "NULL"' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm with TEMPLATE/DISK/VMCATCHER_EVENT_AD_MPURI' do
#     let(:filename) { 'one_worker_vm7.xml'}
#     let(:image_name) { 'https://appdb.egi.eu/store/vo/image/662b0e71-3e21-5f43-b6a1-cc2f51319fa7:156/' }
#
#     it 'uses TEMPLATE/DISK/VMCATCHER_EVENT_AD_MPURI for image id mapping' do
#       expect(subject.process_vm(vm, user_map, image_map)['image_name']).to eq(image_name)
#     end
#   end
#
#   context 'vm without IMAGE_ID' do
#     before :example do
#       data['image_name'] = 'NULL'
#     end
#
#     let(:filename) { 'one_worker_IMAGE_ID_missing.xml' }
#
#     it 'replaces image name with "NULL"' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm without IMAGE_ID mapping' do
#     before :example do
#       data['image_name'] = '31'
#     end
#
#     let(:image_map) { { 'non_existing_id' => 'name' } }
#     let(:filename) { 'one_worker_valid_machine.xml' }
#
#     it 'replaces image name with IMAGE_ID' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
#
#   context 'vm with USER_TEMPLATE/OCCI_COMPUTE_MIXINS' do
#     let(:filename) { 'one_worker_vm4.xml' }
#     let(:image_name) { 'http://occi.localhost/occi/infrastructure/os_tpl#uuid_monitoring_20' }
#
#     it 'w/o map info uses os_tpl mixin' do
#       expect(subject.process_vm(vm, user_map, {})['image_name']).to eq(image_name)
#     end
#
#     it 'w/ map info uses map info' do
#       expect(subject.process_vm(vm, user_map, image_map)['image_name']).to eq(data['image_name'])
#     end
#   end
#
#   context 'vm with USER_TEMPLATE/OCCI_MIXIN' do
#     let(:filename) { 'one_worker_vm5.xml' }
#     let(:image_name) { 'https://occi.localhost/occi/infrastructure/os_tpl#omr_worker_x86_64_ide_1_0' }
#
#     it 'w/o map info uses os_tpl mixin' do
#       expect(subject.process_vm(vm, user_map, {})['image_name']).to eq(image_name)
#     end
#
#     it 'w/ map info uses map info' do
#       expect(subject.process_vm(vm, user_map, image_map)['image_name']).to eq(data['image_name'])
#     end
#   end
#
#   context 'vm with USER_TEMPLATE/USER_X509_DN' do
#     let(:filename) { 'one_worker_vm6.xml' }
#     let(:user_name) { '/MY=STuPID/CN=DN/CN=HERE' }
#
#     it 'w/o map info uses USER_X509_DN' do
#       expect(subject.process_vm(vm, user_map, {})['user_name']).to eq(user_name)
#     end
#
#     it 'w/ map info uses USER_X509_DN' do
#       expect(subject.process_vm(vm, user_map, image_map)['user_name']).to eq(user_name)
#     end
#   end
#
#   context 'vm with DISK SIZEs' do
#     before :example do
#       data['disk_size'] = 53
#     end
#
#     let(:filename) { 'one_worker_vm9.xml' }
#
#     it 'correctly sums disk sizes' do
#       expect(subject.process_vm(vm, user_map, image_map)).to eq(data)
#     end
#   end
# end