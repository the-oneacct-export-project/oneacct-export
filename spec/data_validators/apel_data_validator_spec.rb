require 'spec_helper'

module DataValidators
  describe ApelDataValidator do

    subject { ApelDataValidator.new(Logger.new('/dev/null')) }

    describe '.validate_data' do
      let(:data) do
        data = {}

        data['endpoint'] = 'machine.hogwarts.co.uk'
        data['site_name'] = 'Hogwarts'
        data['cloud_type'] = 'OpenNebula'

        data['vm_uuid'] = '36551'
        data['start_time'] = '1383741160'
        data['end_time'] = '1383742270'
        data['machine_name'] = 'one-36551'
        data['user_id'] = '120'
        data['group_id'] = '0'
        data['user_name'] = 'uname'
        data['group_name'] = 'gname'
        data['status_code'] = '3'
        data['status'] = 'STATUS'
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

        valid_data['endpoint'] = 'machine.hogwarts.co.uk'
        valid_data['site_name'] = 'Hogwarts'
        valid_data['cloud_type'] = 'OpenNebula'

        valid_data['vm_uuid'] = '36551'
        valid_data['start_time'] = Time.at(1383741160)
        valid_data['end_time'] = Time.at(1383742270)
        valid_data['machine_name'] = 'one-36551'
        valid_data['user_id'] = '120'
        valid_data['group_id'] = '0'
        valid_data['user_name'] = 'uname'
        valid_data['group_name'] = 'gname'
        valid_data['status_code'] = '3'
        valid_data['status'] = 'started'
        valid_data['cpu_count'] = '1'
        valid_data['network_inbound'] = 3
        valid_data['network_outbound'] = 5
        valid_data['memory'] = '1736960'
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
        valid_data['history'] = history
        valid_data['disks'] = [{'size' => '10240'}, {'size' => '42368'}]

        valid_data['user_dn'] = '/MY=STuPID/CN=DN/CN=HERE'
        valid_data['image_name'] = 'https://appdb.egi.eu/store/vo/image/blablablabla/'

        valid_data['duration'] = Time.at(685)
        valid_data['suspend'] = 425
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

      context 'without endpoint' do
        before :example do
          data['endpoint'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without site name' do
        before :example do
          data['site_name'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without cloud type' do
        before :example do
          data['cloud_type'] = nil
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

      context 'without start time' do
        before :example do
          data['start_time'] = nil
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with zero start time' do
        before :example do
          data['start_time'] = '0'
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with start time that is not a number' do
        before :example do
          data['start_time'] = 'string'
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without end time' do
        before :example do
          data['end_time'] = nil
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with end time that is not a number' do
        before :example do
          data['end_time'] = 'string'
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with zero end time' do
        before :example do
          data['end_time'] = '0'
          valid_data['end_time'] = 'NULL'
          valid_data['suspend'] = 'NULL'
        end

        it 'it replaces end_time and suspend with "NULL"' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'with start time bigger than end time' do
        before :example do
          time = data['end_time']
          data['end_time'] = data['start_time']
          data['start_time'] = time
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
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

      context 'without user id' do
        before :example do
          data['user_id'] = nil
          valid_data['user_id'] = 'NULL'
        end

        it 'replaces user id with "NULL"' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'without group id' do
        before :example do
          data['group_id'] = nil
          valid_data['group_id'] = 'NULL'
        end

        it 'replaces group id with "NULL"' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'without user dn' do
        before :example do
          data['user_dn'] = nil
          valid_data['user_dn'] = 'NULL'
        end

        it 'replaces user dn with "NULL"' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'without user name' do
        before :example do
          data['user_name'] = nil
          valid_data['user_name'] = 'NULL'
        end

        it 'replaces user name with "NULL"' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'without group name' do
        before :example do
          data['group_name'] = nil
          valid_data['group_name'] = nil
        end

        it 'replaces group name with nil' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'without status code' do
        before :example do
          data['status_code'] = nil
          valid_data['status'] = 'NULL'
          valid_data['status_code'] = nil
        end

        it 'replaces status with "NULL"' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'with status coce out of range' do
        before :example do
          data['status_code'] = '42'
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with status code that is not a number' do
        before :example do
          data['status_code'] = 'string'
          valid_data['status'] = 'NULL'
          valid_data['status_code'] = 'string'
        end

        it 'replaces status with "NULL"' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'without history records' do
        before :example do
          data['history'] = nil
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with empty history records' do
        before :example do
          data['history'] = []
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without cpu count' do
        before :example do
          data['cpu_count'] = nil
          valid_data['cpu_count'] = '1'
        end

        it 'replaces cpu count with 1' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'with cpu count that is not a number' do
        before :example do
          data['cpu_count'] = 'string'
          valid_data['cpu_count'] = '1'
        end

        it 'replaces cpu count with 1' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'with zero cpu count' do
        before :example do
          data['cpu_count'] = '0'
          valid_data['cpu_count'] = '1'
        end

        it 'replaces cpu count with 1' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'without network inbound' do
        before :example do
          data['network_inbound'] = nil
          valid_data['network_inbound'] = 0
        end

        it 'replaces network_inbound with 0' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'with network inbound that is not a number' do
        before :example do
          data['network_inbound'] = 'string'
          valid_data['network_inbound'] = 0
        end

        it 'replaces network_inbound with 0' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'without network outbound' do
        before :example do
          data['network_outbound'] = nil
          valid_data['network_outbound'] = 0
        end

        it 'replaces network outbound with 0' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'with network outbound that is not a number' do
        before :example do
          data['network_outbound'] = 'string'
          valid_data['network_outbound'] = 0
        end

        it 'replaces network outbound with 0' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'without memory' do
        before :example do
          data['memory'] = nil
          valid_data['memory'] = '0'
        end

        it 'replaces memory with 0' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'with memory that is not a number' do
        before :example do
          data['memory'] = 'string'
          valid_data['memory'] = '0'
        end

        it 'replaces memory with 0' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'without image name' do
        before :example do
          data['image_name'] = nil
          valid_data['image_name'] = 'NULL'
        end

        it 'replaces image name with "NULL"' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'without disks' do
        before :example do
          data['disks'] = nil
          valid_data['disks'] = nil
          valid_data['disk_size'] = 'NULL'
        end

        it 'replaces disk size with "NULL"' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end

      context 'with empty disks' do
        before :example do
          data['disks'] = []
          valid_data['disks'] = []
          valid_data['disk_size'] = 0
        end

        it 'replaces disk size with 0' do
          expect(subject.validate_data(data)).to eq(valid_data)
        end
      end
    end
  end
end
