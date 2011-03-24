#
# Author:: Greg Albrecht (<gba@gregalbrecht.com>)
# Copyright:: Copyright (c) 2011 Splunk, Inc. 
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# See Also
#  http://wiki.opscode.com/display/chef/Exception+and+Report+Handlers
#  https://github.com/philk/cloudkick-gem/tree/v2api
#
# Requirements
#  OAuth gem: $ sudo gem install oauth
#
# Usage
#  1. Add these four lines to your /etc/chef/client.rb
#     require 'cloudkick_handler'
#     ck_handler = CloudkickHandler.new(:CONSUMER_KEY => 'xxx', :CONSUMER_SECRET => 'xxx', :check_id => 'xyz')
#     exception_handlers << ck_handler
#     report_handlers << ck_handler
#  2. Copy this file into /var/chef/handler/
#
# TODO
#  1. Add petrics from report_handler to Cloudkick check.
#  2. Document creating Cloudkick check.
# 

require "chef"
require "chef/handler"
require 'rubygems'
require 'oauth'
require 'openssl'

class CloudkickHandler < Chef::Handler

  def initialize(opts = {})
    @config = opts
  end

  def report
    Chef::Log.info("Creating Cloudkick Report...")
    if run_status.failed?
      status = 'err'
      details = run_status.formatted_exception
    else
      status = 'ok'
      details = 'all good'
    end
    OAuth::AccessToken.new( OAuth::Consumer.new(@config[:CONSUMER_KEY], @config[:CONSUMER_SECRET], :site => 'https://api.cloudkick.com', :http_method => :get) ).post("/2.0/check/#{@config[:check_id]}/update_status", { :status => status, :node_id => node[:cloudkick][:data][:id], :details => details } )
  end
end
