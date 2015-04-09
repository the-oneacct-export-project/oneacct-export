require 'spec_helper'

module DataValidators
  describe DataValidatorHelper do
    subject { data_validator_helper }

    let(:data_validator_helper) do
      data_validator_helper = Object.new
      data_validator_helper.extend(Errors)
      data_validator_helper.extend(InputValidator)
      data_validator_helper.extend(DataValidatorHelper)

      data_validator_helper
    end

    describe '.fail_validation' do
      it 'fails with ValidationError' do
        expect { subject.fail_validation('field') }.to raise_error(Errors::ValidationError)
      end
    end

    describe '.default' do
      context 'with :string condition method' do
        context 'with string value' do
          it 'returns back value' do
            expect(subject.default('string', :string, 'default')).to eq('string')
          end
        end
      end

      context 'with :number condition method' do
        context 'with number value' do
          it 'returns back value' do
            expect(subject.default(42, :number, 'default')).to eq(42)
          end
        end

        context 'with non-number value' do
          it 'returns default value' do
            expect(subject.default('string', :number, 'default')).to eq('default')
          end
        end
      end

      context 'with :nzn condition method' do
        context 'with non-zero number value' do
          it 'returns back value' do
            expect(subject.default(42, :nzn, 'default')).to eq(42)
          end
        end

        context 'with zero value' do
          it 'returns default value' do
            expect(subject.default(0, :nzn, 'default')).to eq('default')
          end
        end

        context 'with non-number value' do
          it 'returns default value' do
            expect(subject.default('string', :nzn, 'default')).to eq('default')
          end
        end
      end
    end
  end
end
