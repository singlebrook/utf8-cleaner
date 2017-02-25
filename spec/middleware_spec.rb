require 'spec_helper'
require 'rack/lint'

module UTF8Cleaner
  describe Middleware do
    context 'with invalid method' do
      it 'raises ArgumentError' do
        expect { Middleware.new(nil, :invalid_method) }.to raise_error(ArgumentError)
      end
    end

    context 'with clean method' do
      let(:env) do
        { 'PATH_INFO' => '/this/is/safe', 'QUERY_STRING' => 'foo=bar%FF' }
      end

      let(:new_env) do
        { 'PATH_INFO' => '/this/is/cleaned', 'QUERY_STRING' => 'bar=foo%FF' }
      end

      it 'uses CleanMethod on the env' do
        app = double('app', call: [200, {}, []])
        clean_method = instance_double(Methods::CleanMethod, sanitize_env: new_env)
        allow(Methods::CleanMethod).to receive(:new).with(env) { clean_method }

        Middleware.new(app, :clean).call(env)

        expect(Methods::CleanMethod).to have_received(:new).with(env)
      end

      it 'passes the sanitized env to the app' do
        app = double('app')
        clean_method = instance_double(Methods::CleanMethod, sanitize_env: new_env)
        allow(Methods::CleanMethod).to receive(:new).with(env) { clean_method }
        allow(app).to receive(:call).with(new_env)

        Middleware.new(app, :clean).call(env)

        expect(app).to have_received(:call).with(new_env)
      end
    end
  end
end
