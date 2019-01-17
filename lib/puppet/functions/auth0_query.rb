require_relative '../pops/adapters/auth0_adapter'

Puppet::Functions.create_function(:auth0_query) do
  dispatch :query do
    param 'String', :path
    param 'String', :auth0_client_id
    param 'String', :auth0_client_secret
    param 'String', :auth0_domain
    return_type 'Hash'
  end

  dispatch :implicit_query do
    param 'String', :path
    return_type 'Hash'
  end

  def query(path,id,secret,domain)
    client = Puppet::Pops::Adapters::Auth0Adapter.adapt(closure_scope.compiler).client(id,secret,domain)
    Puppet.info("Querying the Auth0 client")
    client.get(path)
  end

  def implicit_query(path)
    auth0_client_id = call_function('lookup','auth0::management_client_id')
    auth0_client_secret = call_function('lookup','auth0::management_client_secret')
    auth0_domain = call_function('lookup','auth0::managment_domain')
    query(path,auth0_client_id,auth0_client_secret,auth0_domain)
  end
end