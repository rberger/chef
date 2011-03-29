require 'rubygems'
require 'cloudkick'
require 'json'
require 'timeout'

class CloudkickHandler < Chef::Handler

  CHECK_NAME = 'chef-clientRun'
  TIMEOUT = 10
  def initialize(oauth_key, oauth_secret)
    @ckclient = nil
    @cknode = nil
    @oauth_key = oauth_key
    @oauth_secret = oauth_secret
  end

  def connect
    @ckclient = Cloudkick::Base.new(@oauth_key, @oauth_secret)
    @cknode_id = get_node_id
    @check_id = get_check_id
  end

  def reset
    @ckclient = nil
    @cknode = nil
    @check_id = nil
  end

  def report
    begin

      Timeout::timeout(TIMEOUT) do
        if not @ckclient or not @cknode_id or not @check_id
          connect
        end
        if not @ckclient or not @cknode_id or not @check_id
          return
        end

        status = { }
        if run_status.success?
          status['status'] = 'ok'
          status['details'] = 'Chef run completed in ' + run_status.elapsed_time.to_s
        else
          status['status']= 'err'
          status['details'] = 'Chef run failed: ' + run_status.formatted_exception
        end
        if run_status.elapsed_time
          elapsed_time = run_status.elapsed_time.to_s
        else
          elapsed_time = 0
        end

        if run_status.all_resources
          all_resources_length = run_status.all_resources.length.to_s
        else
          all_resources_length = 0
        end

        if run_status.updated_resources
          updated_resources_length = run_status.updated_resources.length.to_s
        else
          updated_resources_length = 0
        end


        metrics = [ ]
        metrics << { 'metric_name' => 'elapsed_time',
                     'value' => elapsed_time,
                     'check_type' => 'float' }
        metrics << { 'metric_name' => 'all_resources',
                     'value' => all_resources_length,
                     'check_type' => 'int' }
        metrics << { 'metric_name' => 'updated_resources',
                     'value' => updated_resources_length,
                     'check_type' => 'int' }

        begin
          send_status(status)
          send_metrics(metrics)
        rescue
          return
        end
      end
    rescue Timeout::Error
      reset
    end
  end

  def send_status(status)
    status['node_id'] = @cknode_id.to_s
    resp, data = @ckclient.access_token.post('/2.0/check/' + @check_id + '/update_status', status)
    if not resp.code =~ /^2/
      reset
    end
  end

  def send_metrics(metrics)
    metrics.each do |m|
      m['node_id'] = @cknode_id.to_s
      resp, data = @ckclient.access_token.post('/2.0/data/check/' + @check_id, m)
      if not resp.code =~ /^2/
        reset
        return
      end
    end
  end

  def get_node_id
    resp, data = @ckclient.access_token.get("/2.0/nodes?query=node:#{node.fqdn}")
    if not resp.code =~ /^2/
      reset
      return nil
    end
    parsed = JSON::parse(data)
    if parsed['items'].first['name'] == node.fqdn
      return parsed['items'].first['id']
    end
    return nil
  end

  def get_check_id
    resp, data = @ckclient.access_token.get('/2.0/checks')
    if not resp.code =~ /^2/
      raise Exception, "received " + resp.code.to_s + " on list checks"
      reset
      return nil
    end
    parsed = JSON::parse(data)

    parsed['items'].each do |item|
      if CHECK_NAME == item['details']['name']
        return item['id']
      end
    end
    return nil
  end
end
