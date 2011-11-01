begin
  require 'rack'
  require 'json'
rescue LoadError
  abort "ERROR: whats_up_adhearsion requires the 'rack' and 'json' gems"
end

begin
  require 'active_record'
    class ActiveRecord::ConnectionAdapters::ConnectionPool
      attr_reader :checked_out, :size
    end
rescue LoadError
end

WHATS_UP_ADHEARSION_HANDLER = lambda do |env|
  json = env["rack.input"].read
  json = json.blank? ? nil : JSON.parse(json)
  path = env["PATH_INFO"]
  path = path[1..-1]
  rpc_object = Adhearsion::Components.component_manager.extend_object_with(Object.new, :rpc)
  response_object = rpc_object.send(path, *json)
  [200, {"Content-Type" => response_object[:type]}, Array(response_object[:response])]
end

initialization do
  config = COMPONENTS.send :'whats-up-adhearsion'
  api = WHATS_UP_ADHEARSION_HANDLER
  handler = Rack::Handler.const_get('Mongrel')
  Thread.new do
    handler.run api, :Port => 5005
  end
end

methods_for :rpc do
  def health()
    {:type => 'text/html; charset=UTF-8', :response => 'good'}
  end

  def status()
    response_hash = {:number_of_calls => Adhearsion.active_calls.size}
    begin
      response_hash[:db_pool_active] = ActiveRecord::Base.connection_pool.checked_out.size
      response_hash[:db_pool_cached] = ActiveRecord::Base.connection_pool.connections.size
      response_hash[:db_pool_max] = ActiveRecord::Base.connection_pool.size
    rescue NameError
    end
    {:type => 'application/json', :response => JSON.generate(response_hash)}
  end
end

