require 'spec_helper'

describe RedisConf do
  subject { redisconf }

  let(:redisconf) { RedisConf }
  let(:default_options) { { namespace: 'oneacct_export', url: 'redis://localhost:6379' } }

  describe '#options' do
    context 'without redis options set' do
      before :example do
        Settings.redis['namespace'] = nil
        Settings.redis['url'] = nil
        Settings.redis['password'] = nil
      end

      it 'will use default values' do
        expect(subject.options).to eq(default_options)
      end
    end

    context 'with different namespace' do
      before :example do
        Settings.redis['namespace'] = 'custom_namespace'
        Settings.redis['url'] = nil
        Settings.redis['password'] = nil
      end

      it 'will correctly assign custom namespace' do
        options = default_options.clone
        options[:namespace] = 'custom_namespace'
        expect(subject.options).to eq(options)
      end
    end

    context 'with different url' do
      before :example do
        Settings.redis['namespace'] = nil
        Settings.redis['password'] = nil
      end

      context 'that is a valid url' do
        before :example do
          Settings.redis['url'] = 'redis://machine.hogworts:1234'
        end

        it 'will correctly assign custom url' do
          options = default_options.clone
          options[:url] = 'redis://machine.hogworts:1234'
          expect(subject.options).to eq(options)
        end
      end

      context 'that is not a valid url' do
        before :example do
          Settings.redis['url'] = 'qwerty_)(*@%?>'
        end

        it 'will raise an ArgumentError' do
          expect { subject.options }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with different password' do
      before :example do
        Settings.redis['namespace'] = nil
        Settings.redis['url'] = nil
      end

      context 'that is a valid password' do
        before :example do
          Settings.redis['password'] = 'secret_password'
        end

        it 'will correctly insert password into url' do
          options = default_options.clone
          options[:url] = 'redis://:secret_password@localhost:6379'
          expect(subject.options).to eq(options)
        end
      end

      context 'that is not a valid password' do
        before :example do
          Settings.redis['password'] = ''
        end

        it 'will raise an ArgumentError' do
          expect { subject.options }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
