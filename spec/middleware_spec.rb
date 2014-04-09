require 'spec_helper'
require 'rack/lint'

describe UTF8Cleaner::Middleware do
  let :env do
    {
      'PATH_INFO' => 'foo/%FFbar%2e%2fbaz%26%3B',
      'QUERY_STRING' => 'foo=bar%FF',
      'HTTP_REFERER' => 'http://example.com/blog+Result:+%ED%E5+%ED%E0%F8%EB%EE%F1%FC+%F4%EE%F0%EC%FB+%E4%EB%FF+%EE%F2%EF%F0%E0%E2%EA%E8',
      'REQUEST_URI' => '%C3%89%E2%9C%93',
      'rack.input' => StringIO.new('foo=%FFbar%F8')
    }
  end

  let :new_env do
    UTF8Cleaner::Middleware.new(nil).send(:sanitize_env, env)
  end

  describe "removes invalid UTF-8 sequences" do
    it { new_env['QUERY_STRING'].should == 'foo=bar' }
    it { new_env['HTTP_REFERER'].should == 'http://example.com/blog+Result:+++++' }
    it { new_env['rack.input'].read.should == 'foo=bar' }
  end

  describe "leaves all valid characters untouched" do
    it { new_env['PATH_INFO'].should == 'foo/bar%2e%2fbaz%26%3B' }
    it { new_env['REQUEST_URI'].should == '%C3%89%E2%9C%93' }
  end

  describe "removes invalid UTF-8 sequences when rack.input is wrapped" do
    # rack.input responds only to methods gets, each, rewind, read and close
    # Rack::Lint::InputWrapper is the class which servers wrappers are based on
    it do
      wrapped_rack_input = Rack::Lint::InputWrapper.new(StringIO.new('foo=%FFbar%F8'))
      wrapped_env = env.merge('rack.input' => wrapped_rack_input)
      new_env = UTF8Cleaner::Middleware.new(nil).send(:sanitize_env, wrapped_env)
      new_env['rack.input'].read.should == 'foo=bar'
    end
  end
end
