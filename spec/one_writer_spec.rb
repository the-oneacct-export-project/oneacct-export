require 'spec_helper'

describe OneWriter do
  subject { one_writer }
  before :example do
    Settings.output['output_type'] = 'one_writer_test_output_type'
  end

  let(:data) { { 'aaa' => 111, 'bbb' => 222 } }
  let(:testfile) { "#{GEM_DIR}/mock/one_writer_testfile" }
  let(:dev_null) { '/dev/null' }
  let(:output) { "#{GEM_DIR}/mock/one_writer_output" }

  describe '#new' do
    context 'with correct arguments' do
      before :example do
        allow(OneWriter).to receive(:template_filename) { testfile }
      end

      let(:one_writer) do
        OneWriter.new(data, output, dev_null)
      end

      it 'takes three parameters and returns OneWriter object' do
        is_expected.to be_an_instance_of OneWriter
      end

      it 'correctly assigns three parameters' do
        expect(subject.data).to eq(data)
        expect(subject.output).to eq(output)
        expect(subject.log).to eq(dev_null)
      end
    end

    context 'with incorrect arguments' do
      before :example do
        allow(OneWriter).to receive(:template_filename) { testfile }
      end

      it 'fails with ArgumentError if output is nil' do
        expect { OneWriter.new(data, nil, dev_null) }.to\
          raise_error(ArgumentError)
      end

      it 'fails with ArgumentError if data is nil' do
        expect { OneWriter.new(nil, output, dev_null) }.to raise_error(ArgumentError)
      end
    end

    context 'with non existing template file' do
      before :example do
        allow(OneWriter).to receive(:template_filename) { 'non_existing' }
      end

      it 'fails with ArgumentError' do
        expect { OneWriter.new(data, output, dev_null) }.to\
          raise_error(ArgumentError)
      end
    end
  end

  describe '#template_filename' do
    it 'returns template name in form of filename within template directory' do
      expect(OneWriter.template_filename('test')).to eq("#{GEM_DIR}/lib/templates/test.erb")
    end
  end

  describe '.fill_template' do
    before :example do
      allow(OneWriter).to receive(:template_filename) { testfile }
    end

    let(:one_writer) do
      OneWriter.new(data, output, Logger.new(dev_null))
    end

    it 'returns result version of a template with data' do
      expect(subject.fill_template).to eq("aaa: 111\nbbb: 222")
    end
  end

  describe '.write_to_tmp' do
    before :example do
      allow(OneWriter).to receive(:template_filename) { testfile }
    end

    after :example do
      File.delete(tmp) if File.exist?(tmp)
    end

    let(:tmp) { File.open("#{GEM_DIR}/mock/one_writer_tmp", 'w') }
    let(:one_writer) do
      OneWriter.new(data, output, Logger.new(dev_null))
    end

    it 'writes data into temporary file' do
      subject.write_to_tmp(tmp, data)
      expect(File.read(tmp)).to eq(data.to_s)
    end
  end

  describe '.copy_to_output' do
    before :example do
      allow(OneWriter).to receive(:template_filename) { testfile }
    end

    after :example do
      File.delete(to) if File.exist?(to)
    end

    let(:from) { testfile }
    let(:to) { "#{GEM_DIR}/mock/one_writer_copy" }
    let(:one_writer) do
      OneWriter.new(data, output, Logger.new(dev_null))
    end

    it 'copies temporary file to output file' do
      subject.copy_to_output(from, to)
      expect(File.read(from)).to eq(File.read(to))
    end
  end

  describe '.write' do
    before :example do
      allow(OneWriter).to receive(:template_filename) { testfile }
      allow(subject).to receive(:fill_template) { data }
      allow(Tempfile).to receive(:new) { tmp }
    end

    let(:one_writer) do
      OneWriter.new(data, output, Logger.new(dev_null))
    end
    let(:tmp) do
      tmp = double('tmp')
      allow(tmp).to receive(:path) { "#{GEM_DIR}/mock/one_writer_tmp" }
      tmp
    end

    it 'writes result version of a template into output file' do
      expect(subject).to receive(:write_to_tmp).with(tmp, data)
      expect(subject).to receive(:copy_to_output).with("#{GEM_DIR}/mock/one_writer_tmp", output)
      expect(tmp).to receive(:close)
      subject.write
    end
  end
end
