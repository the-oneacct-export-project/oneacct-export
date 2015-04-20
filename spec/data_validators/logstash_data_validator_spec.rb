require 'rspec'

module DataValidators
  describe LogstashDataValidator do

    subject { LogstashDataValidator.new(Logger.new('/dev/null')) }

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
        valid_data['start_time'] = 1383741160
        valid_data['end_time'] = 1383742270
        valid_data['machine_name'] = 'one-36551'
        valid_data['user_id'] = 120
        valid_data['group_id'] = 0
        valid_data['user_name'] = 'uname'
        valid_data['group_name'] = 'gname'
        valid_data['status_code'] = 3
        valid_data['status'] = 'STATUS'
        valid_data['cpu_count'] = 1
        valid_data['network_inbound'] = 4154845418
        valid_data['network_outbound'] = 6326418701
        valid_data['memory'] = 1736960
        history = []
        rec = {}
        rec['start_time'] = 1383741169
        rec['end_time'] = 1383741259
        rec['rstart_time'] = 1383741278
        rec['rend_time'] = 1383741367
        rec['seq'] = 0
        rec['hostname'] = 'supermachine1.somewhere.com'
        history << rec
        rec = {}
        rec['start_time'] = 1383741589
        rec['end_time'] = 1383742270
        rec['rstart_time'] = 1383741674
        rec['rend_time'] = 1383742270
        rec['seq'] = 1
        rec['hostname'] = 'supermachine2.somewhere.com'
        history << rec
        valid_data['history'] = history
        valid_data['disks'] = [{'size' => 10240}, {'size' => 42368}]

        valid_data['user_dn'] = '/MY=STuPID/CN=DN/CN=HERE'
        valid_data['image_name'] = 'https://appdb.egi.eu/store/vo/image/blablablabla/'

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

      context 'without user id' do
        before :example do
          data['user_id'] = nil
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with user id that is not a number' do
        before :example do
          data['user_id'] = 'string'
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without group id' do
        before :example do
          data['group_id'] = nil
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with group id that is not a number' do
        before :example do
          data['group_id'] = 'string'
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without status_code' do
        before :example do
          data['status_code'] = nil
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end


      context 'with status_code that is not a number' do
        before :example do
          data['status_code'] = 'string'
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without cpu count' do
        before :example do
          data['cpu_count'] = nil
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with cpu count that is not a number' do
        before :example do
          data['cpu_count'] = 'string'
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without network inbound' do
        before :example do
          data['network_inbound'] = nil
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with network inbound that is not a number' do
        before :example do
          data['network_inbound'] = 'string'
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without network outbound' do
        before :example do
          data['network_outbound'] = nil
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with network outbound that is not a number' do
        before :example do
          data['network_outbound'] = 'string'
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without memory' do
        before :example do
          data['memory'] = nil
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with memory that is not a number' do
        before :example do
          data['memory'] = 'string'
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without disks' do
        before :example do
          data['disks'] = nil
        end

        it 'it fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without history' do
        before :example do
          data['history'] = nil
        end

        it 'it fails with ValidationError' do
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

      context 'without rstart time in history record' do
        before :example do
          data['history'][0]['rstart_time'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with rstart time in history record that is not a number' do
        before :example do
          data['history'][0]['rstart_time'] = 'string'
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with rstart time in history record that is zero' do
        before :example do
          data['history'][0]['rstart_time'] = '0'
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'without rend time in history record' do
        before :example do
          data['history'][0]['rend_time'] = nil
        end

        it 'fails with ValidationError' do
          expect { subject.validate_data(data) }.to raise_error(Errors::ValidationError)
        end
      end

      context 'with rend time in history record that is not a number' do
        before :example do
          data['history'][0]['rend_time'] = 'string'
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
    end
  end
end
