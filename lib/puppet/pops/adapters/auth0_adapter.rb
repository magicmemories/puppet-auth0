require 'auth0'

class Puppet::Pops::Adapters::Auth0Adapter < Puppet::Pops::Adaptable::Adapter
  def initialize
    @cache = {}
  end

  def client(id,secret,domain)
    @cache[domain] ||= {}
    @cache[domain][id] ||= create_client(id,secret,domain)
  end
    
  private
  def create_client(id,secret,domain)
    Auth0::Client.new(
      client_id: id,
      client_secret: secret,
      domain: domain,
    )
  end
end
    