require 'spec_helper'
require 'rack/lint'

module UTF8Cleaner
  describe Middleware do
    let :new_env do
      Middleware.new(nil).send(:sanitize_env, env)
    end

    describe "with a big nasty env" do
      let :host do
        "\xD0".force_encoding('ASCII-8BIT')
      end

      let :env do
        {
          'PATH_INFO' => 'foo/%FFbar%2e%2fbaz%26%3B',
          'QUERY_STRING' => 'foo=bar%FF',
          'HTTP_REFERER' => 'http://example.com/blog+Result:+%ED%E5+%ED%E0%F8%EB%EE%F1%FC+%F4%EE%F0%EC%FB+%E4%EB%FF+%EE%F2%EF%F0%E0%E2%EA%E8',
          'HTTP_USER_AGENT' => "Android Versi\xF3n/4.0\x93",
          'REQUEST_URI' => '%C3%89%E2%9C%93',
          'rack.input' => StringIO.new("foo=%FFbar%F8"),
          'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
          'HTTP_COOKIE' => nil,
          'SERVER_NAME' => host,
          'HTTP_HOST' => host
        }
      end

      describe 'host could be encoded to utf-8' do
        it { expect(host.encoding.to_s).to eq('ASCII-8BIT') }
        it { expect(new_env['HTTP_HOST'].encoding.to_s).to eq('UTF-8') }
        it { expect(new_env['HTTP_HOST']).to eq(host.force_encoding('UTF-8')) }
      end

      describe "removes invalid %-encoded UTF-8 sequences" do
        it { expect(new_env['QUERY_STRING']).to eq('foo=bar') }
        it { expect(new_env['HTTP_REFERER']).to eq('http://example.com/blog+Result:+++++') }
        it { expect(new_env['rack.input'].read).to eq('foo=bar') }
      end

      describe 'replaces \x-encoded characters from the ISO-8859-1 and CP1252 code pages with their UTF-8 equivalents' do
        it { expect(new_env['HTTP_USER_AGENT']).to eq("Android Versi\u00F3n/4.0\u201C") }
      end

      describe "leaves all valid characters untouched" do
        it { expect(new_env['PATH_INFO']).to eq('foo/bar%2e%2fbaz%26%3B') }
        it { expect(new_env['REQUEST_URI']).to eq('%C3%89%E2%9C%93') }
      end

      describe "when rack.input is wrapped" do
        # rack.input responds only to methods gets, each, rewind, read and close
        # Rack::Lint::InputWrapper is the class which servers wrappers are based on
        it "removes invalid UTF-8 sequences" do
          wrapped_rack_input = Rack::Lint::InputWrapper.new(StringIO.new("foo=%FFbar%F8"))
          env.merge!('rack.input' => wrapped_rack_input)
          new_env = Middleware.new(nil).send(:sanitize_env, env)
          expect(new_env['rack.input'].read).to eq('foo=bar')
        end
      end

      describe "when binary data is POSTed" do
        before do
          env['CONTENT_TYPE'] = 'multipart/form-data'
        end
        it "leaves the body alone" do
          env['rack.input'].rewind
          expect(new_env['rack.input'].read).to eq "foo=%FFbar%F8"
        end
      end

      describe "when json data is POSTed" do
        before do
          env['CONTENT_TYPE'] = 'application/json'
        end

        it "tidies invalid UTF-8 sequences" do
          env['rack.input'] = StringIO.new(%Q({"foo": "\xFFbar\xF8"}))
          env['rack.input'].rewind
          expect(new_env['rack.input'].read).to eq(%Q({"foo": "\u00FFbar\u00F8"}))
        end

        it "does not attempt to URI-decode data" do
          json = %Q({"foo": "%FF"})
          env['rack.input'] = StringIO.new(json)
          env['rack.input'].rewind
          expect(new_env['rack.input'].read).to eq(json)
        end
      end
    end

    describe "with a minimal env" do
      let(:env) do
        {
          'PATH_INFO' => '/this/is/safe',
          'QUERY_STRING' => 'foo=bar%FF'
        }
      end

      it "only runs URIString cleaning on potentially unclean strings" do
        expect(URIString).to receive(:new).once.and_call_original
        new_env
      end

      it "leaves clean values alone" do
        expect(new_env['PATH_INFO']).to eq('/this/is/safe')
      end
    end

    # Ensure that all cleaned values parse cleanly.
    # E.g. make sure Rack/Rails won't choke on them
    after do
      cleaned = new_env
      env.keys.reject{|key| key == 'rack.input'}.each do |key|
        URI.decode_www_form_component(cleaned[key]) if cleaned[key]
      end
    end
  end
end
