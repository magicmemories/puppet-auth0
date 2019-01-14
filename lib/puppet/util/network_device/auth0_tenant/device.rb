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
  end
end


