require 'forwardable'
require 'puppet/util/network_device/simple/device'
require 'auth0'

module Puppet::Util::NetworkDevice::Auth0_tenant
  class Device < Puppet::Util::NetworkDevice::Simple::Device
    extend Forwardable
    include Auth0::Api::V2

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
      { 'operatingsystem' => 'auth0' }
    end

    def_delegators :@connection, :get, :post, :post_file, :put, :patch, :delete

    # These methods are missing from the Auth0 gem for some reason, a PR is in progress
    # but in the meantime we'll just stick it here.
    def resource_servers(page: nil, per_page: nil)
      request_params = {
        page: !page.nil? ? page.to_i : nil,
        per_page: !page.nil? && !per_page.nil? ? per_page.to_i : nil
      }
      get(resource_servers_path, request_params)
    end
    alias get_resource_servers resource_servers

    def patch_resource_server(id, options)
      raise Auth0::MissingClientId, 'Must specify a resource server id' if id.to_s.empty?
      raise Auth0::MissingParameter, 'Must specify a valid body' if options.to_s.empty?
      path = "#{resource_servers_path}/#{id}"
      patch(path, options)
    end
  end
end


