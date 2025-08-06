# frozen_string_literal: true

require 'spec_helper'
require 'rack'
require 'rack/test'
require 'json'

describe 'UTF8Cleaner::Middleware Integration' do
  include Rack::Test::Methods

  let(:app) do
    Rack::Builder.new do
      use UTF8Cleaner::Middleware
      run(lambda do |env|
        # Create a Rack::Request to properly parse parameters
        request = Rack::Request.new(env)

        # Echo back the sanitized environment for verification
        response_body = {
          path_info: env['PATH_INFO'],
          query_string: env['QUERY_STRING'],
          request_uri: env['REQUEST_URI'],
          request_path: env['REQUEST_PATH'],
          http_referer: env['HTTP_REFERER'],
          http_user_agent: env['HTTP_USER_AGENT'],
          http_cookie: env['HTTP_COOKIE']
        }

        # Include parsed params for form data testing
        if env['REQUEST_METHOD'] == 'POST' && env['CONTENT_TYPE']&.match?(%r{application/x-www-form-urlencoded}i)
          response_body[:params] = begin
            request.POST
          rescue StandardError
            {}
          end
        elsif env['CONTENT_TYPE']&.match?(%r{application/json}i)
          env['rack.input'].rewind
          response_body[:payload] = env['rack.input'].read
          env['rack.input'].rewind
        elsif env['CONTENT_TYPE']&.match?(%r{multipart/form-data}i)
          response_body[:multipart_size] = env['rack.input'].read.bytesize
          env['rack.input'].rewind
        end

        begin
          [200, { 'Content-Type' => 'application/json' }, [response_body.to_json]]
        rescue JSON::GeneratorError
          [200, { 'Content-Type' => 'text/plain' }, response_body[:payload]]
        end
      end)
    end
  end

  describe 'GET requests' do
    context 'with invalid UTF-8' do
      it 'removes invalid percent-encoded sequences from query string' do
        env = Rack::MockRequest.env_for('/')
        env['QUERY_STRING'] = 'name=%FFbad%F8&valid=true'

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['query_string']).to eq('name=bad&valid=true')
      end

      it 'cleans invalid sequences from path_info' do
        env = Rack::MockRequest.env_for('/test/path')
        env['PATH_INFO'] = '/test/%FFbad%F8/path'

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['path_info']).to eq('/test/bad/path')
      end

      it 'handles mixed valid and invalid encodings' do
        env = Rack::MockRequest.env_for('/')
        env['QUERY_STRING'] = 'good=%E2%9C%93&bad=%FF&mixed=%E2%9C%FF'

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['query_string']).to eq('good=%E2%9C%93&bad=&mixed=')
      end

      it 'handles truncated multibyte sequences' do
        # %E2%9C%93 is ✓, but truncate it at different points
        env = Rack::MockRequest.env_for('/')
        env['QUERY_STRING'] = 'truncated=%E2%9C&complete=%E2%9C%93'

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['query_string']).to eq('truncated=&complete=%E2%9C%93')
      end

      it 'handles overlong UTF-8 sequences' do
        # Overlong encoding of '/' (should be %2F but encoded as %C0%AF)
        env = Rack::MockRequest.env_for('/')
        env['QUERY_STRING'] = 'overlong=%C0%AF&normal=text'

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['query_string']).to eq('overlong=&normal=text')
      end

      it 'handles invalid continuation bytes' do
        # Valid start byte but invalid continuation
        env = Rack::MockRequest.env_for('/')
        env['QUERY_STRING'] = 'invalid=%E2%FF%93&valid=test'

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['query_string']).to eq('invalid=&valid=test')
      end
    end

    context 'percent encodings' do
      it 'preserves valid percent-encoded characters' do
        env = Rack::MockRequest.env_for('/test%2Fpath?foo=%26bar%3D1')
        _status, _headers, body = app.call(env)

        response = JSON.parse(body.first)
        expect(response['path_info']).to eq('/test%2Fpath')
        expect(response['query_string']).to eq('foo=%26bar%3D1')
      end

      it 'removes incomplete percent encodings' do
        env = Rack::MockRequest.env_for('/')
        env['QUERY_STRING'] = 'incomplete=%2'

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['query_string']).to eq('incomplete=')
      end

      it 'removes percent signs without hex chars' do
        env = Rack::MockRequest.env_for('/')
        env['QUERY_STRING'] = 'invalid=%GG&partial=%F'

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['query_string']).to eq('invalid=G&partial=')
      end

      it 'removes bare percent signs' do
        env = Rack::MockRequest.env_for('/')
        env['QUERY_STRING'] = 'percent=%&value=test'

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['query_string']).to eq('percent=value=test')
      end
    end
  end

  describe 'POST requests' do
    context 'with form-encoded data' do
      it 'cleans invalid UTF-8 in form parameters' do
        env = Rack::MockRequest.env_for('/',
                                        'REQUEST_METHOD' => 'POST',
                                        'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
                                        :input => 'name=%FFbad%F8&email=test@example.com')

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['params']).to eq({
                                           'name' => 'bad',
                                           'email' => 'test@example.com'
                                         })
      end

      it 'preserves valid UTF-8 in form data' do
        env = Rack::MockRequest.env_for('/',
                                        'REQUEST_METHOD' => 'POST',
                                        'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
                                        :input => 'name=José&city=São+Paulo')

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['params']).to eq({
                                           'name' => 'José',
                                           'city' => 'São Paulo'
                                         })
      end

      it 'handles complex mixed encodings in forms' do
        env = Rack::MockRequest.env_for('/',
                                        'REQUEST_METHOD' => 'POST',
                                        'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
                                        :input => 'valid=%E2%9C%93&invalid=%FF&text=hello%20world')

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['params']).to eq({
                                           'valid' => '✓',
                                           'invalid' => '',
                                           'text' => 'hello world'
                                         })
      end

      it 'handles form data with no content type' do
        env = Rack::MockRequest.env_for('/',
                                        'REQUEST_METHOD' => 'POST',
                                        :input => 'test=%FFdata')

        status, _headers, _body = app.call(env)
        expect(status).to eq(200)
      end

      it 'handles empty POST body' do
        env = Rack::MockRequest.env_for('/',
                                        'REQUEST_METHOD' => 'POST',
                                        'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
                                        'CONTENT_LENGTH' => '0',
                                        :input => '')

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['params']).to eq({})
      end
    end

    context 'with JSON data' do
      it 'tidies invalid UTF-8 bytes in JSON' do
        pending 'This case is not currently handled correctly' unless defined?(TruffleRuby)

        # Create JSON with invalid UTF-8 bytes
        json_with_invalid = "{\"name\": \"test\xFF\xF8\", \"valid\": \"✓\"}"

        env = Rack::MockRequest.env_for('/',
                                        'REQUEST_METHOD' => 'POST',
                                        'CONTENT_TYPE' => 'application/json',
                                        :input => json_with_invalid)

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        # Invalid bytes should be replaced with replacement characters
        expect(JSON.parse(response['payload'])).to eq({
                                                        'name' => "test\u00FF\u00F8",
                                                        'valid' => '✓'
                                                      })
      end

      it 'does not URI-decode JSON content' do
        json = { 'encoded' => '%20%26%3D', 'normal' => 'text' }.to_json

        env = Rack::MockRequest.env_for('/',
                                        'REQUEST_METHOD' => 'POST',
                                        'CONTENT_TYPE' => 'application/json',
                                        :input => json)

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(JSON.parse(response['payload'])).to eq({
                                                        'encoded' => '%20%26%3D',
                                                        'normal' => 'text'
                                                      })
      end

      it 'handles valid UTF-8 JSON unchanged' do
        skip if RUBY_VERSION < '3.1' || defined?(JRuby) || defined?(TruffleRuby)

        json = { 'name' => 'José', 'emoji' => '😀', 'check' => '✓' }.to_json

        env = Rack::MockRequest.env_for('/',
                                        'REQUEST_METHOD' => 'POST',
                                        'CONTENT_TYPE' => 'application/json',
                                        :input => json)

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(JSON.parse(response['payload'])).to eq({
                                                        'name' => 'José',
                                                        'emoji' => '😀',
                                                        'check' => '✓'
                                                      })
      end
    end

    context 'with multipart/form-data' do
      it 'handles multipart form data with invalid UTF-8 in field names' do
        input = <<~INPUT
          --AaB03x\r
          content-disposition: form-data; name="field%FFname"\r
          \r
          value\r
          --AaB03x--\r
        INPUT

        env = Rack::MockRequest.env_for('/',
                                        'REQUEST_METHOD' => 'POST',
                                        'CONTENT_TYPE' => 'multipart/form-data; boundary=AaB03x',
                                        'CONTENT_LENGTH' => input.size.to_s,
                                        :input => input)

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['multipart_size']).to be > 0
      end

      it 'does not modify binary content in multipart' do
        skip if RUBY_VERSION < '3.1' || defined?(TruffleRuby)

        # Create binary content with invalid UTF-8
        binary_content = (+"file\xFF\xF8content").force_encoding('BINARY')

        # Build multipart request manually
        boundary = 'AaB03x'
        input = "--#{boundary}\r\n"
        input << "content-disposition: form-data; name=\"file\"; filename=\"test.bin\"\r\n"
        input << "content-type: application/octet-stream\r\n"
        input << "\r\n"
        input << binary_content
        input << "\r\n--#{boundary}--\r\n"

        env = Rack::MockRequest.env_for('/',
                                        'REQUEST_METHOD' => 'POST',
                                        'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}",
                                        'CONTENT_LENGTH' => input.bytesize.to_s,
                                        :input => StringIO.new(input))

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['multipart_size']).to eq(input.bytesize)
      end
    end
  end

  describe 'HTTP headers' do
    context 'with invalid UTF-8 in headers' do
      it 'cleans User-Agent header' do
        env = Rack::MockRequest.env_for('/', 'HTTP_USER_AGENT' => "Mozilla/5.0\xFF\xF8")

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['http_user_agent']).to eq("Mozilla/5.0\u00FF\u00F8")
      end

      it 'cleans Referer header with invalid percent encoding' do
        env = Rack::MockRequest.env_for('/', 'HTTP_REFERER' => 'http://example.com/search?q=%FFbad%F8')

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['http_referer']).to eq('http://example.com/search?q=bad')
      end

      it 'cleans Cookie header' do
        env = Rack::MockRequest.env_for('/', 'HTTP_COOKIE' => 'session=%FFbad%F8; user=john')

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['http_cookie']).to eq('session=bad; user=john')
      end

      it 'handles multiple cookies with invalid encoding' do
        env = Rack::MockRequest.env_for('/',
                                        'HTTP_COOKIE' => 'first=%FFbad; second=good%20value; third=%F8invalid')

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['http_cookie']).to eq('first=bad; second=good%20value; third=invalid')
      end
    end

    context 'with valid UTF-8 in headers' do
      it 'preserves valid UTF-8 in headers' do
        env = Rack::MockRequest.env_for('/',
                                        'HTTP_REFERER' => 'http://example.com/José',
                                        'HTTP_USER_AGENT' => 'Custom/1.0 (São Paulo)')

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['http_referer']).to eq('http://example.com/José')
        expect(response['http_user_agent']).to eq('Custom/1.0 (São Paulo)')
      end

      it 'preserves valid percent-encoded UTF-8 in referer' do
        env = Rack::MockRequest.env_for('/',
                                        'HTTP_REFERER' => 'http://example.com/search?q=%E2%9C%93')

        _status, _headers, body = app.call(env)
        response = JSON.parse(body.first)
        expect(response['http_referer']).to eq('http://example.com/search?q=%E2%9C%93')
      end
    end
  end

  describe 'REQUEST_URI and REQUEST_PATH' do
    it 'cleans both REQUEST_URI and REQUEST_PATH' do
      env = Rack::MockRequest.env_for('/test')
      env['REQUEST_URI'] = '/test%FFpath?query=%FFparam'
      env['REQUEST_PATH'] = '/test%FFpath'
      env['QUERY_STRING'] = 'query=%FFparam'

      _status, _headers, body = app.call(env)
      response = JSON.parse(body.first)
      expect(response['request_uri']).to eq('/testpath?query=param')
      expect(response['request_path']).to eq('/testpath')
      expect(response['query_string']).to eq('query=param')
    end

    it 'handles REQUEST_URI with fragment identifiers' do
      env = Rack::MockRequest.env_for('/')
      env['REQUEST_URI'] = '/page?param=%FFvalue#section'
      env['QUERY_STRING'] = 'param=%FFvalue'

      _status, _headers, body = app.call(env)
      response = JSON.parse(body.first)
      expect(response['request_uri']).to eq('/page?param=value#section')
    end
  end

  describe 'edge cases' do
    it 'handles empty rack.input gracefully' do
      env = Rack::MockRequest.env_for('/',
                                      'REQUEST_METHOD' => 'POST',
                                      'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
                                      :input => nil)

      status, _headers, _body = app.call(env)
      expect(status).to eq(200)
    end

    it 'handles very long invalid sequences' do
      long_invalid = '%FF' * 100
      env = Rack::MockRequest.env_for('/')
      env['QUERY_STRING'] = "data=#{long_invalid}"

      _status, _headers, body = app.call(env)
      response = JSON.parse(body.first)
      expect(response['query_string']).to eq('data=')
    end

    it 'handles mixed case content-type headers' do
      env = Rack::MockRequest.env_for('/',
                                      'REQUEST_METHOD' => 'POST',
                                      'CONTENT_TYPE' => 'Application/X-WWW-Form-URLEncoded',
                                      :input => 'test=%FFdata')

      _status, _headers, body = app.call(env)
      response = JSON.parse(body.first)
      expect(response['params']).to eq({ 'test' => 'data' })
    end

    it 'preserves plus signs as spaces in form data' do
      env = Rack::MockRequest.env_for('/',
                                      'REQUEST_METHOD' => 'POST',
                                      'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
                                      :input => 'text=hello+world+test')

      _status, _headers, body = app.call(env)
      response = JSON.parse(body.first)
      expect(response['params']).to eq({ 'text' => 'hello world test' })
    end

    it 'handles null bytes in input' do
      env = Rack::MockRequest.env_for('/')
      env['QUERY_STRING'] = "null=\x00&text=hello"

      _status, _headers, body = app.call(env)
      response = JSON.parse(body.first)
      # Should preserve null bytes that are valid
      expect(response['query_string']).to include('text=hello')
    end

    it 'handles Safari ajax POST body with null terminator' do
      env = Rack::MockRequest.env_for('/',
                                      'REQUEST_METHOD' => 'POST',
                                      'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
                                      :input => "foo=bar&quux=bla\0")

      _status, _headers, body = app.call(env)
      response = JSON.parse(body.first)
      expect(response['params']).to eq({ 'foo' => 'bar', 'quux' => 'bla' })
    end
  end

  describe 'complex real-world scenarios' do
    it 'handles a request with multiple invalid encodings across different parts' do
      env = Rack::MockRequest.env_for('/pathinfo',
                                      'REQUEST_METHOD' => 'POST',
                                      'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
                                      'HTTP_REFERER' => 'http://example.com/page%FFtest',
                                      'HTTP_USER_AGENT' => "Bot\xFF\xF8/1.0",
                                      'HTTP_COOKIE' => 'id=%FFbad',
                                      :input => 'field=%FFvalue')

      env['PATH_INFO'] = '/path%FFinfo'
      env['QUERY_STRING'] = 'param=%FFquery'
      env['REQUEST_URI'] = '/path%FFinfo?param=%FFquery'
      env['REQUEST_PATH'] = '/path%FFinfo'

      _status, _headers, body = app.call(env)
      response = JSON.parse(body.first)

      expect(response['path_info']).to eq('/pathinfo')
      expect(response['query_string']).to eq('param=query')
      expect(response['request_uri']).to eq('/pathinfo?param=query')
      expect(response['request_path']).to eq('/pathinfo')
      expect(response['http_referer']).to eq('http://example.com/pagetest')
      expect(response['http_user_agent']).to eq("Bot\u00FF\u00F8/1.0")
      expect(response['http_cookie']).to eq('id=bad')
      expect(response['params']).to eq({ 'field' => 'value' })
    end

    it 'handles requests with byte sequences at buffer boundaries' do
      # Test sequences that might be split at typical buffer sizes
      # This tests the middleware's ability to handle partial sequences
      env = Rack::MockRequest.env_for('/')
      # Create a query string that puts invalid bytes at common buffer boundaries
      env['QUERY_STRING'] = "#{'a' * 8190}%FF#{'b' * 10}"

      _status, _headers, body = app.call(env)
      response = JSON.parse(body.first)
      expect(response['query_string']).to eq(('a' * 8190) + ('b' * 10))
    end
  end

  describe 'middleware composition' do
    let(:app) do
      Rack::Builder.new do
        use UTF8Cleaner::Middleware
        run ->(_env) { [200, { 'content_type' => 'text/plain' }, ['OK']] }
      end
    end

    it 'works correctly with other middleware' do
      env = Rack::MockRequest.env_for('/?test=%FFbad')
      status, _headers, body = app.call(env)
      expect(status).to eq(200)
      expect(body).to eq(['OK'])
    end
  end

  describe 'rack.input rewind behavior' do
    it 'ensures rack.input can be read multiple times' do
      test_app = Rack::Builder.new do
        use UTF8Cleaner::Middleware
        run lambda { |env|
          # First read
          env['rack.input'].rewind
          first_read = env['rack.input'].read

          # Second read
          env['rack.input'].rewind
          second_read = env['rack.input'].read

          [
            200,
            { 'Content-Type' => 'application/json' },
            [{ first: first_read, second: second_read, same: first_read == second_read }.to_json]
          ]
        }
      end

      env = Rack::MockRequest.env_for('/',
                                      'REQUEST_METHOD' => 'POST',
                                      'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
                                      :input => 'test=%FFdata')

      _status, _headers, body = test_app.call(env)
      response = JSON.parse(body.first)
      expect(response['first']).to eq('test=data')
      expect(response['second']).to eq('test=data')
      expect(response['same']).to be true
    end
  end

  describe 'performance considerations' do
    it 'handles large payloads efficiently' do
      # Create a large form payload with some invalid sequences
      large_data = (1..1000).map { |i| "field#{i}=value#{i}" }.join('&')
      large_data += '&invalid=%FFtest'

      env = Rack::MockRequest.env_for('/',
                                      'REQUEST_METHOD' => 'POST',
                                      'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
                                      :input => large_data)

      _status, _headers, body = app.call(env)
      response = JSON.parse(body.first)
      expect(response['params']).to include('field1' => 'value1')
      expect(response['params']).to include('field1000' => 'value1000')
      expect(response['params']).to include('invalid' => 'test')
    end
  end
end
