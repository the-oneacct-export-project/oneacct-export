require 'spec_helper'

describe OneacctOpts do
  before :example do
    allow(OneWriter).to receive(:template_filename) { "#{GEM_DIR}/mock/one_writer_testfile" }
  end

  let(:options) { OpenStruct.new }

  describe '#set_defaults' do
    context 'with empty options' do
      it 'sets the default values' do
        OneacctOpts.set_defaults(options)
        expect(options.blocking).to eq(OneacctOpts::BLOCKING_DEFAULT)
        expect(options.timeout).to be_nil
        expect(options.compatibility).to eq(OneacctOpts::COMPATIBILITY_DEFAULT)
      end
    end

    context 'with blocking set' do
      before :example do
        options.blocking = true
      end

      it 'keeps the blocking option' do
        OneacctOpts.set_defaults(options)
        expect(options.blocking).to eq(true)
        expect(options.timeout).to eq(OneacctOpts::TIMEOUT_DEFAULT)
        expect(options.compatibility).to eq(OneacctOpts::COMPATIBILITY_DEFAULT)
      end
    end

    context 'with timeout set' do
      before :example do
        options.timeout = 42
      end

      it 'keeps the blocking option' do
        OneacctOpts.set_defaults(options)
        expect(options.blocking).to eq(OneacctOpts::BLOCKING_DEFAULT)
        expect(options.timeout).to eq(42)
        expect(options.compatibility).to eq(OneacctOpts::COMPATIBILITY_DEFAULT)
      end
    end

    context 'with compatibility set' do
      before :example do
        options.compatibility = true
      end

      it 'keeps the blocking option' do
        OneacctOpts.set_defaults(options)
        expect(options.blocking).to eq(OneacctOpts::BLOCKING_DEFAULT)
        expect(options.timeout).to be_nil
        expect(options.compatibility).to eq(true)
      end
    end
  end

  describe '#check_options_restrictions' do
    context 'with wrong time range' do
      before :example do
        options.records_from = (Time.new + 1000)
        options.records_to = (Time.new - 1000)
      end

      it 'fails with ArgumentError' do
        expect { OneacctOpts.check_options_restrictions(options) }.to raise_error(ArgumentError)
      end
    end

    context 'with mixed groups' do
      before :example do
        options.include_groups = ['group']
        options.exclude_groups = ['group']
      end

      it 'fails with ArgumentError' do
        expect { OneacctOpts.check_options_restrictions(options) }.to raise_error(ArgumentError)
      end
    end

    context 'with group file set without group restriction type' do
      before :example do
        options.groups_file = 'file'
      end

      it 'fails with ArgumentError' do
        expect { OneacctOpts.check_options_restrictions(options) }.to raise_error(ArgumentError)
      end
    end

    context 'with timout set without blocking option' do
      before :example do
        options.timeout = 50
      end

      it 'fails with ArgumentError' do
        expect { OneacctOpts.check_options_restrictions(options) }.to raise_error(ArgumentError)
      end
    end

    context 'with correct set of options' do
      before :example do
        options.records_from = (Time.new - 1000)
        options.records_to = (Time.new + 1000)
        options.include_groups = []
        options.groups_file = 'file'
        options.blocking = true
        options.timeout = 50
      end

      it 'finishes without any failure' do
        OneacctOpts.check_options_restrictions(options)
      end
    end
  end

  describe '#check_settings_restrictions' do
    before :example do
      Settings.output['output_dir'] = '/some/output/dir'
      Settings.output['output_type'] = 'apel-v0.2'
      Settings.logging['log_type'] = 'file'
      Settings.logging['log_file'] = '/var/log/oneacct.log'
    end

    context 'with missing mandatory paramter' do
      context 'output_dir' do
        before :example do
          Settings.output['output_dir'] = nil
        end

        it 'fails with ArgumentError' do
          expect { OneacctOpts.check_settings_restrictions }.to raise_error(ArgumentError)
        end
      end

      context 'output_type' do
        before :example do
          Settings.output['output_type'] = nil
        end

        it 'fails with ArgumentError' do
          expect { OneacctOpts.check_settings_restrictions }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with missing mandatory paramter of Apel output type' do
      before :example do
        Settings.output['output_type'] = 'apel-0.2'
      end

      context 'site_name' do
        before :example do
          Settings.output.apel['site_name'] = nil
        end

        it 'fails with ArgumentError' do
          expect { OneacctOpts.check_settings_restrictions }.to raise_error(ArgumentError)
        end
      end

      context 'cloud_type' do
        before :example do
          Settings.output.apel['cloud_type'] = nil
        end

        it 'fails with ArgumentError' do
          expect { OneacctOpts.check_settings_restrictions }.to raise_error(ArgumentError)
        end
      end

      context 'endpoint' do
        before :example do
          Settings.output.apel['endpoint'] = nil
        end

        it 'fails with ArgumentError' do
          expect { OneacctOpts.check_settings_restrictions }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with missing mandatory paramter of PBS output type' do
      before :example do
        Settings.output['output_type'] = 'pbs-0.1'
      end

      context 'realm' do
        before :example do
          Settings.output.pbs['realm'] = nil
        end

        it 'fails with ArgumentError' do
          expect { OneacctOpts.check_settings_restrictions }.to raise_error(ArgumentError)
        end
      end

      context 'queue' do
        before :example do
          Settings.output.pbs['queue'] = nil
        end

        it 'fails with ArgumentError' do
          expect { OneacctOpts.check_settings_restrictions }.to raise_error(ArgumentError)
        end
      end

      context 'scratch_type' do
        before :example do
          Settings.output.pbs['scratch_type'] = nil
        end

        it 'fails with ArgumentError' do
          expect { OneacctOpts.check_settings_restrictions }.to raise_error(ArgumentError)
        end
      end

      context 'host_identifier' do
        before :example do
          Settings.output.pbs['host_identifier'] = nil
        end

        it 'fails with ArgumentError' do
          expect { OneacctOpts.check_settings_restrictions }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with logging set to file without file specified' do
      before :example do
        Settings.logging['log_type'] = 'file'
        Settings.logging['log_file'] = nil
      end

      it 'fails with ArgumentError' do
        expect { OneacctOpts.check_settings_restrictions }.to raise_error(ArgumentError)
      end
    end

    context 'with non existing template' do
      before :example do
        allow(OneWriter).to receive(:template_filename) { 'nonexisting_file' }
      end

      it 'fails with ArgumentError' do
        expect { OneacctOpts.check_settings_restrictions }.to raise_error(ArgumentError)
      end
    end

    context 'with all settings correct' do
      it 'finishes without any failure' do
        OneacctOpts.check_settings_restrictions
      end
    end
  end

  describe '#parse' do
    before :example do
      Settings.output['output_dir'] = '/some/output/dir'
      Settings.output['output_type'] = 'pbs-v0.2'
      Settings.output.pbs['realm'] = 'REALM'
      Settings.output.pbs['queue'] = 'queue'
      Settings.output.pbs['scratch_type'] = 'local'
      Settings.output.pbs['host_identifier'] = 'on_localhost'
      Settings.logging['log_type'] = 'file'
      Settings.logging['log_file'] = '/var/log/oneacct.log'
    end

    let(:args) { ['--records-from', '01.01.2014', '--records-to', '01.07.2014', '--include-groups', 'aaa,bbb,ccc', '-b', '-t', '50', '-c'] }

    it 'returns correctly parsed options' do
      options = OneacctOpts.parse(args)
      expect(options.records_from).to be_instance_of(Time)
      expect(options.records_from).to eq(Time.new(2014, 1, 1))
      expect(options.records_to).to be_instance_of(Time)
      expect(options.records_to).to eq(Time.new(2014, 7, 1))
      expect(options.include_groups).to be_instance_of(Array)
      expect(options.include_groups).to eq(%w(aaa bbb ccc))
      expect(options.blocking).to be_instance_of(TrueClass)
      expect(options.blocking).to be true
      expect(options.timeout).to be_instance_of(Fixnum)
      expect(options.timeout).to eq(50)
      expect(options.compatibility).to be_instance_of(TrueClass)
      expect(options.compatibility).to be true
    end
  end
end
