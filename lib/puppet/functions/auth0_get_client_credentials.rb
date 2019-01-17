require_relative '../pops/adaptable/adatpers/auth0_adapter'

Puppet::Functions.create_function(:auth0_get_client_credentials) do
  dispatch :query do
    param 'String', :client_name
    param 'String', :auth0_client_id
    param 'String', :auth0_client_secret
    param 'String', :auth0_domain
    return_type 'Hash'
  end

  dispatch :implicit_query do
    param 'String', path
    return_type 'Hash'
  end

  def query(client_name,id,secret,domain)
    api_client = Puppet::Pops::Adaptable::Adapters::Auth0Adapter.adapt(closure_scope.compiler).client(id,secret,domain)
    Puppet.info("Querying the Auth0 client")
    # TODO: handle paging
    client = api_client.get_clients.find_all {|c| c['name'] == client_name }
    {client_id: client['client_id'], client_secret: client['client_secret']}
  end

  def implicit_query(path)
    auth0_client_id = call_function('lookup','auth0::management_client_id')
    auth0_client_secret = call_function('lookup','auth0::management_client_secret')
    auth0_domain = call_function('lookup','auth0::managment_domain')
    query(path,auth0_client_id,auth0_client_secret,auth0_domain)
  end
end