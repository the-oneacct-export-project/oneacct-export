require 'spec_helper'

module DataValidators
  describe DataValidator do

    subject { DataValidator.new }

    describe '.validate_data' do
      it 'fails with NotImplementedError' do
        expect { subject.validate_data }.to raise_error(Errors::NotImplementedError)
      end
    end
  end
end