require 'forwardable'
require 'puppet/util/network_device/simple/device'
require 'auth0'

module Puppet::Util::NetworkDevice::Auth0_tenant
  class Device < Puppet::Util::NetworkDevice::Simple::Device

    PAGINATED_METHODS = %i{
      clients get_clients client_grants get_all_client_grants rules get_rules
      connections get_connections resource_servers get_resource_servers
    }

    Auth0::Api::V2.instance_methods.each do |method|
      # The way **kwargs is handled changed in Ruby 2.7.0
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7.0')
        define_method(method) do |*args, **kwargs|
          handling_rate_limit do
            if PAGINATED_METHODS.include?(method)
              paginate_request(method, *args, **kwargs)
            else
              @connection.send(method, *args, **kwargs)
            end
          end
        end
      else
        define_method(method) do |*args|
          handling_rate_limit do
            if PAGINATED_METHODS.include?(method)
              paginate_request(method, *args)
            else
              @connection.send(method, *args)
            end
          end
        end
      end
    end

    attr_reader :connection
    def initialize(*args)
      super
      @connection = Auth0::Client.new(
        client_id: config['client_id'],
        client_secret: config['client_secret'],
        domain: config['domain'],
        api_version: 2,
      )
    end

    def facts
      {
        tenant_domain: config['domain'],
        management_client_id: config['client_id'],
      }
    end

    def handling_rate_limit
      begin
        yield
      rescue Auth0::RateLimitEncountered => rle
        retry_after = Time.now - rle.reset
        if retry_after > 0
          Puppet.warning("Encountered rate limit, will delay #{retry_after} seconds and try again.")
          sleep(retry_after)
          yield
        else
          Puppet.warning("Encountered rate limit but rate-limit-reset has already occurred, trying again immediately.")
          yield
        end
      end
    end

    def paginate_request(method, *args, **kwargs)
      results = []
      0.step do |page|
        real_kwargs = kwargs.merge(page: page, per_page: 50)
        result = @connection.send(method, *args, **real_kwargs)
        break if result.empty?
        results.concat(result)
      end
      results
    end
  end
end
