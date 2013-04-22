# -*- encoding: utf-8 -*-
require 'spec_helper'

describe 'UTF8Cleaner::Middleware' do
  let :env do
    {
      'PATH_INFO' => 'foo/bar%2e%2fbaz',
      'QUERY_STRING' => '%FF',
      'HTTP_REFERER' => 'http://example.com/%FF',
      'REQUEST_URI' => '%C3%89'
    }
  end

  let :new_env do
    UTF8Cleaner::Middleware.new(nil).send(:sanitize_env, env)
  end

  it "removes invalid UTF-8 sequences" do
    new_env['QUERY_STRING'].should == ''
    new_env['HTTP_REFERER'].should == 'http://example.com/'
  end

  it "turns valid %-escaped ASCII chars into their ASCII equivalents" do
    new_env['PATH_INFO'].should == 'foo/bar./baz'
  end

  it "leaves valid %-escaped UTF-8 chars alone" do
    new_env['REQUEST_URI'].should == '%C3%89'
  end
end