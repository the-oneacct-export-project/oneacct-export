require 'spec_helper'

module DataValidators
  describe PbsDataValidator do

    subject { PbsDataValidator.new }

    describe '.validate_data' do
      let(:data) do
        data = {}

        data['pbs_queue'] = 'queue'
        data['realm'] = 'REALM'
        data['host'] = 'on_localhost'
        data['scratch_type'] = 'local'

        data['vm_uuid'] = '36551'
        data['start_time'] = '1383741160'
        data['end_time'] = '1383742270'
        data['machine_name'] = 'one-36551'
        data['user_id'] = '120'
        data['group_id'] = '0'
        data['user_name'] = 'uname'
        data['group_name'] = 'gname'
        data['status'] = '3'
        data['cpu_count'] = '1'
        data['network_inbound'] = '4154845418'
        data['network_outbound'] = '6326418701'
        data['memory'] = '1736960'
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
        data['history'] = history
        data['disks'] = [{'size' => '10240'}, {'size' => '42368'}]

        data['user_dn'] = '/MY=STuPID/CN=DN/CN=HERE'
        data['image_name'] = 'https://appdb.egi.eu/store/vo/image/blablablabla/'

        data
      end

      let(:valid_data) do
        valid_data = {}

        valid_data['pbs_queue'] = 'queue'
        valid_data['realm'] = 'REALM'
        valid_data['host'] = 'on_localhost'
        valid_data['scratch_type'] = 'local'

        valid_data['vm_uuid'] = '36551'
        valid_data['start_time'] = '1383741160'
        valid_data['end_time'] = '1383742270'
        valid_data['machine_name'] = 'one-36551'
        valid_data['user_id'] = '120'
        valid_data['group_id'] = '0'
        valid_data['user_name'] = 'uname'
        valid_data['group_name'] = 'gname'
        valid_data['status'] = '3'
        valid_data['cpu_count'] = '1'
        valid_data['network_inbound'] = '4154845418'
        valid_data['network_outbound'] = '6326418701'
        valid_data['memory'] = '1736960'
        history = []
        rec = {}
        rec['start_time'] = Time.at(1383741169)
        rec['end_time'] = Time.at(1383741259)
        rec['rstart_time'] = '1383741278'
        rec['rend_time'] = '1383741367'
        rec['seq'] = '0'
        rec['hostname'] = 'supermachine1.somewhere.com'
        rec['state'] = 'U'
        history << rec
        rec = {}
        rec['start_time'] = Time.at(1383741589)
        rec['end_time'] = Time.at(1383742270)
        rec['rstart_time'] = '1383741674'
        rec['rend_time'] = '1383742270'
        rec['seq'] = '1'
        rec['hostname'] = 'supermachine2.somewhere.com'
        rec['state'] = 'U'
        history << rec
        valid_data['history'] = history
        valid_data['disks'] = [{'size' => '10240'}, {'size' => '42368'}]

        valid_data['user_dn'] = '/MY=STuPID/CN=DN/CN=HERE'
        valid_data['image_name'] = 'https://appdb.egi.eu/store/vo/image/blablablabla/'

        valid_data['duration'] = Time.at(685)
        valid_data['disk_size'] = 52608

        valid_data
      end

      context 'with all data valid' do
        it 'returns the same data transformed if needed' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'without any data' do
        let(:data) { nil }

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with empty data' do
        let(:data) { {} }

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without host' do
        before :example do
          data['host'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without queue' do
        before :example do
          data['pbs_queue'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without realm' do
        before :example do
          data['realm'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without vm uuid' do
        before :example do
          data['vm_uuid'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without user name' do
        before :example do
          data['user_name'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without group name' do
        before :example do
          data['group_name'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without cpu count' do
        before :example do
          data['cpu_count'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with cpu count that is not a number' do
        before :example do
          data['cpu_count'] = 'string'
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without memory' do
        before :example do
          data['memory'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with memory that is not a number' do
        before :example do
          data['memory'] = 'string'
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without history records' do
        before :example do
          data['history'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with empty history records' do
        before :example do
          data['history'] = []
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without start time in history record' do
        before :example do
          data['history'][0]['start_time'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without start time in history record' do
        before :example do
          data['history'][0]['start_time'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with start time in history record that is not a number' do
        before :example do
          data['history'][0]['start_time'] = 'string'
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with start time in history record that is zero' do
        before :example do
          data['history'][0]['start_time'] = '0'
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without end time in history record' do
        before :example do
          data['history'][0]['end_time'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with end time in history record that is not a number' do
        before :example do
          data['history'][0]['end_time'] = 'string'
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without sequence number in history record' do
        before :example do
          data['history'][0]['seq'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with sequence number in history record that is not a number' do
        before :example do
          data['history'][0]['seq'] = 'string'
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without hostname in history record' do
        before :example do
          data['history'][0]['hostname'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end
      
      context 'with stopped virtual machine' do
        before :example do
          data['status'] = '6'
          valid_data['history'][1]['state'] = 'E'
          valid_data['status'] = '6'
        end

        it 'sets last history record\'s state to "E"' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'without machine name' do
        before :example do
          data['machine_name'] = nil
        end

        it 'replaces machine name with string created from id and prefix "one-"' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end
    end
  end
end