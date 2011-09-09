require 'adhearsion'
require 'adhearsion/component_manager/spec_framework'
require 'flexmock/rspec'

def ComponentTester.new(component_name, component_directory, main_file = nil)
      component_directory = File.expand_path component_directory
      main_file ||= "/#{component_name}/lib/#{component_name}.rb"
      main_file.insert 0, component_directory

      component_manager = Adhearsion::Components::ComponentManager.new(component_directory)
      component_module  = Adhearsion::Components::ComponentManager::ComponentDefinitionContainer.load_file main_file

      Module.new do

        extend ComponentTester

        (class << self; self; end).send(:define_method, :component_manager)   { component_manager   }
        (class << self; self; end).send(:define_method, :component_name)      { component_name      }
        (class << self; self; end).send(:define_method, :component_module)    { component_module    }
        (class << self; self; end).send(:define_method, :component_directory) { component_directory }


        define_method(:component_manager)   { component_manager   }
        define_method(:component_name)      { component_name      }
        define_method(:component_module)    { component_module    }
        define_method(:component_directory) { component_directory }

        def self.const_missing(name)
          component_module.const_get name
        end

      end
    end

RSpec::Runner.configure do |config|
  config.mock_with :flexmock
end

WHATS_UP_ADHEARSION = ComponentTester.new("whats-up-adhearsion", File.dirname(__FILE__) + "/../..")

##### This is here for a reference
#{"CONTENT_LENGTH"       => "12",
# "CONTENT_TYPE"         => "application/x-www-form-urlencoded",
# "GATEWAY_INTERFACE"    => "CGI/1.1",
# "HTTP_ACCEPT"          => "application/xml",
# "HTTP_ACCEPT_ENCODING" => "gzip, deflate",
# "HTTP_AUTHORIZATION"   => "Basic amlja3N0YTpyb2ZsY29wdGVyeg==",
# "HTTP_HOST"            => "localhost:5000",
# "HTTP_VERSION"         => "HTTP/1.1",
# "PATH_INFO"            => "/rofl",
# "QUERY_STRING"         => "",
# "rack.errors"          => StringIO.new(""),
# "rack.input"           => StringIO.new('["o","hai!"]'),
# "rack.multiprocess"    => false,
# "rack.multithread"     => true,
# "rack.run_once"        => false,
# "rack.url_scheme"      => "http",
# "rack.version"         => [0, 1],
# "REMOTE_ADDR"          => "::1",
# "REMOTE_HOST"          => "localhost",
# "REMOTE_USER"          => "jicksta",
# "REQUEST_METHOD"       => "POST"
# "REQUEST_PATH"         => "/",
# "REQUEST_URI"          => "http://localhost:5000/rofl",
# "SCRIPT_NAME"          => "",
# "SERVER_NAME"          => "localhost",
# "SERVER_PORT"          => "5000",
# "SERVER_PROTOCOL"      => "HTTP/1.1",
# "SERVER_SOFTWARE"      => "WEBrick/1.3.1 (Ruby/1.8.6/2008-03-03)"}

describe "The initialization block" do

  it "should create a new Thread" do
    mock_component_config_with :'whats-up-adhearsion' => {}
    flexmock(Thread).should_receive(:new).and_return { nil }
    flexmock(Rack::Handler).should_receive(:const_get).and_return Rack::Handler::Mongrel 
    WHATS_UP_ADHEARSION.initialize!
  end

  it "should run the Rack adapter specified in the configuration" do
    flexmock(Thread).should_receive(:new)
    mock_component_config_with :'whats-up-ahhearsion' => {"adapter" => "Mongrel"}
    flexmock(Rack::Handler).should_receive(:const_get).and_return Rack::Handler::Mongrel 
    flexmock(Rack::Handler::Mongrel).should_receive(:run).with(Proc, :Port => 5000)
    WHATS_UP_ADHEARSION.initialize!
  end

end

describe 'Private helper methods' do

  describe "the RESTFUL_API_HANDLER lambda" do

    it "should return a 200 for requests which execute a method that has been defined in the methods_for(:rpc) context" do
      component_manager = Adhearsion::Components::ComponentManager.new('/path/shouldnt/matter')

      flexmock(Adhearsion::Components).should_receive(:component_manager).and_return { component_manager }
      component_manager.load_code <<-RUBY
        methods_for(:rpc) do
          def testing_123456(one,two)
            {:type => 'application/json', :response => JSON.generate([two.reverse, one.reverse])}
          end
        end
      RUBY

      input = StringIO.new %w[jay phillips].to_json

      mock_component_config_with :restful_rpc => {"path_nesting" => "/"}

      env = {"PATH_INFO" => "/testing_123456", "rack.input" => input}

      response = WHATS_UP_ADHEARSION::WHATS_UP_ADHEARSION_HANDLER.call(env)
      response.should be_kind_of(Array)
      response.should have(3).items
      response.first.should equal(200)
      JSON.parse(response.last).should eql(%w[jay phillips].map(&:reverse).reverse)
    end

    it "should allow calls with no data POSTed" do
      component_manager = Adhearsion::Components::ComponentManager.new('/path/shouldnt/matter')

      flexmock(Adhearsion::Components).should_receive(:component_manager).and_return { component_manager }
      component_manager.load_code <<-RUBY
        methods_for(:rpc) do
          def foobar()
            {:type => 'application/json', :response => JSON.generate(['hello'])}
          end
        end
      RUBY

      env = {"rack.input" => StringIO.new(""), "PATH_INFO" => "/foobar"}
      
      response = WHATS_UP_ADHEARSION::WHATS_UP_ADHEARSION_HANDLER.call(env)
      response.first.should equal(200)
      JSON.parse(response.last).first.should == 'hello'
    end

    it "should work with a high level test of a successful method invocation" do

      component_manager = Adhearsion::Components::ComponentManager.new('/path/shouldnt/matter')

      flexmock(Adhearsion::Components).should_receive(:component_manager).and_return { component_manager }

      component_manager.load_code '
        methods_for(:rpc) do
          def rofl(one,two)
            {:type => "application/json", :response => JSON.generate(["Hai! #{one} #{two}"])}
          end
        end'

      env = {
        "CONTENT_LENGTH"       => "12",
        "CONTENT_TYPE"         => "application/x-www-form-urlencoded",
        "GATEWAY_INTERFACE"    => "CGI/1.1",
        "HTTP_ACCEPT"          => "application/xml",
        "HTTP_ACCEPT_ENCODING" => "gzip, deflate",
        "HTTP_AUTHORIZATION"   => "Basic amlja3N0YTpyb2ZsY29wdGVyeg==",
        "HTTP_HOST"            => "localhost:5000",
        "HTTP_VERSION"         => "HTTP/1.1",
        "PATH_INFO"            => "/rofl",
        "QUERY_STRING"         => "",
        "rack.errors"          => StringIO.new(""),
        "rack.input"           => StringIO.new('["o","hai!"]'),
        "rack.multiprocess"    => false,
        "rack.multithread"     => true,
        "rack.run_once"        => false,
        "rack.url_scheme"      => "http",
        "rack.version"         => [0, 1],
        "REMOTE_ADDR"          => "::1",
        "REMOTE_HOST"          => "localhost",
        "REMOTE_USER"          => "jicksta",
        "REQUEST_METHOD"       => "POST",
        "REQUEST_PATH"         => "/",
        "REQUEST_URI"          => "http://localhost:5000/rofl",
        "SCRIPT_NAME"          => "",
        "SERVER_NAME"          => "localhost",
        "SERVER_PORT"          => "5000",
        "SERVER_PROTOCOL"      => "HTTP/1.1",
        "SERVER_SOFTWARE"      => "WEBrick/1.3.1 (Ruby/1.8.6/2008-03-03)" }

      response = WHATS_UP_ADHEARSION::WHATS_UP_ADHEARSION_HANDLER.call(env)
      JSON.parse(response.last).should == ["Hai! o hai!"]
    end
  end
end

