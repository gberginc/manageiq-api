RSpec.describe 'Configuration Script Sources API' do
  let(:provider) { FactoryBot.create(:ext_management_system) }
  let(:config_script_src) { FactoryBot.create(:ansible_configuration_script_source, :manager => provider) }
  let(:config_script_src_2) { FactoryBot.create(:ansible_configuration_script_source, :manager => provider) }
  let(:ansible_provider)      { FactoryBot.create(:provider_ansible_tower, :with_authentication) }
  let(:manager) { ansible_provider.managers.first }

  describe 'GET /api/configuration_script_sources' do
    it 'lists all the configuration script sources with an appropriate role' do
      repository = FactoryBot.create(:configuration_script_source)
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :read, :get)

      get(api_configuration_script_sources_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'configuration_script_sources',
        'resources' => [hash_including('href' => api_configuration_script_source_url(nil, repository))]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to configuration script sources without an appropriate role' do
      api_basic_authorize

      get(api_configuration_script_sources_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/configuration_script_sources/:id' do
    let(:repository) { FactoryBot.create(:configuration_script_source) }

    it 'will show a configuration script source with an appropriate role' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :read, :get)
      get(api_configuration_script_source_url(nil, repository))

      expected = {'href' => api_configuration_script_source_url(nil, repository)}

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'allows accessing verify_ssl for EmbeddedAnsible::AutomationManager::ConfigurationScriptSource' do
      embedded_ansible_repository = FactoryBot.create(:embedded_ansible_configuration_script_source)
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :read, :get)
      get(api_configuration_script_source_url(nil, embedded_ansible_repository,
                                              :attributes => "name,description,verify_ssl"))

      expected = {
        'name'        => embedded_ansible_repository.name,
        'description' => embedded_ansible_repository.description,
        'verify_ssl'  => 0
      }

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to a configuration script source without an appropriate role' do
      api_basic_authorize
      get(api_configuration_script_source_url(nil, repository))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/configuration_script_sources' do
    let(:params) do
      {
        :id          => config_script_src.id,
        :name        => 'foo',
        :description => 'bar'
      }
    end

    it 'will bulk update configuration_script_sources with an appropriate role' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :edit, :post)
      params2 = params.dup.merge(:id => config_script_src_2.id)

      post(api_configuration_script_sources_url, :params => { :action => 'edit', :resources => [params, params2] })

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Updating ConfigurationScriptSource'),
            'task_id' => a_kind_of(String)
          ),
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Updating ConfigurationScriptSource'),
            'task_id' => a_kind_of(String)
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids updating configuration_script_sources without an appropriate role' do
      api_basic_authorize

      post(api_configuration_script_sources_url, :params => { :action => 'edit', :resources => [params] })

      expect(response).to have_http_status(:forbidden)
    end

    it 'will delete multiple configuration script source with an appropriate role' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :delete, :post)

      post(api_configuration_script_sources_url, :params => { :action => 'delete', :resources => [{:id => config_script_src.id}, {:id => config_script_src_2.id}] })
      expect_multiple_action_result(2, :success => true, :task => true, :message => /Deleting Configuration Script Source/)
    end

    it 'forbids delete without an appropriate role' do
      api_basic_authorize

      post(api_configuration_script_sources_url, :params => { :action => 'delete', :resources => [{:id => config_script_src.id}] })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can refresh multiple configuration_script_source with an appropriate role' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :refresh, :post)

      post(api_configuration_script_sources_url, :params => { :action => :refresh, :resources => [{ :id => config_script_src.id}, {:id => config_script_src_2.id}] })

      expected = {
        'results' => [
          a_hash_including(
            'success'   => true,
            'message'   => a_string_including("Refreshing Configuration Script Source id: #{config_script_src.id}"),
            'task_id'   => a_kind_of(String),
            'task_href' => /task/,
            'tasks'     => [a_hash_including('id' => a_kind_of(String), 'href' => /task/)]
          ),
          a_hash_including(
            'success'   => true,
            'message'   => a_string_including("Refreshing Configuration Script Source id: #{config_script_src_2.id}"),
            'task_id'   => a_kind_of(String),
            'task_href' => /task/,
            'tasks'     => [a_hash_including('id' => a_kind_of(String), 'href' => /task/)]
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'PUT /api/configuration_script_sources/:id' do
    let(:params) do
      {
        :name        => 'foo',
        :description => 'bar'
      }
    end

    it 'updates a configuration_script_source with an appropriate role' do
      api_basic_authorize action_identifier(:configuration_script_sources, :edit)

      put(api_configuration_script_source_url(nil, config_script_src), :params => { :resource => params })

      expected = {
        'success' => true,
        'message' => a_string_including('Updating ConfigurationScriptSource'),
        'task_id' => a_kind_of(String)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'PATCH /api/configuration_script_sources/:id' do
    let(:params) do
      {
        :action      => 'edit',
        :name        => 'foo',
        :description => 'bar'
      }
    end

    it 'updates a configuration_script_source with an appropriate role' do
      api_basic_authorize action_identifier(:configuration_script_sources, :edit)

      patch(api_configuration_script_source_url(nil, config_script_src), :params => [params])

      expected = {
        'success' => true,
        'message' => a_string_including('Updating ConfigurationScriptSource'),
        'task_id' => a_kind_of(String)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/configuration_script_sources/:id' do
    let(:params) do
      {
        :name        => 'foo',
        :description => 'bar'
      }
    end

    it 'updates a configuration_script_source with an appropriate role' do
      api_basic_authorize action_identifier(:configuration_script_sources, :edit)

      post(api_configuration_script_source_url(nil, config_script_src), :params => { :action => 'edit', :resource => params })

      expected = {
        'success' => true,
        'message' => a_string_including('Updating ConfigurationScriptSource'),
        'task_id' => a_kind_of(String)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires that the type support update_in_provider_queue' do
      config_script_src = FactoryBot.create(:configuration_script_source)
      api_basic_authorize action_identifier(:configuration_script_sources, :edit)

      post(api_configuration_script_source_url(nil, config_script_src), :params => { :action => 'edit', :resource => params })

      expected = {
        'success' => false,
        'message' => "Update not supported for ConfigurationScriptSource id:#{config_script_src.id} name: '#{config_script_src.name}'"
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids updating a configuration_script_source without an appropriate role' do
      api_basic_authorize

      post(api_configuration_script_source_url(nil, config_script_src), :params => { :action => 'edit', :resource => params })

      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids refresh without an appropriate role' do
      api_basic_authorize

      post(api_configuration_script_source_url(nil, config_script_src), :params => { :action => 'refresh' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'can refresh a configuration_script_source with an appropriate role' do
      api_basic_authorize action_identifier(:configuration_script_sources, :refresh)

      post(api_configuration_script_source_url(nil, config_script_src), :params => { :action => :refresh })

      expected = {
        'success'   => true,
        'message'   => /Refreshing Configuration Script Source/,
        'task_id'   => a_kind_of(String),
        'task_href' => /task/,
        'tasks'     => [a_hash_including('id' => a_kind_of(String), 'href' => /tasks/)]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can delete a configuration_script_source with an appropriate role' do
      api_basic_authorize action_identifier(:configuration_script_sources, :delete)

      post(api_configuration_script_source_url(nil, config_script_src), :params => { :action => 'delete' })
      expect_single_action_result(:success => true, :task => true, :message => /Deleting Configuration Script Source/)
    end

    it 'requires that the type support delete_in_provider_queue' do
      config_script_src = FactoryBot.create(:configuration_script_source)
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :delete, :post)

      post(api_configuration_script_source_url(nil, config_script_src), :params => { :action => 'delete', :resource => params })
      expect_bad_request(/Delete not supported for Configuration Script Source/)
    end

    it 'forbids configuration script source delete without an appropriate role' do
      api_basic_authorize

      post(api_configuration_script_source_url(nil, config_script_src), :params => { :action => 'delete' })

      expect(response).to have_http_status(:forbidden)
    end

    let(:create_params) do
      {
        :manager_resource => { :href => api_provider_url(nil, manager) },
        :description      => 'Description',
        :name             => 'My Project',
        :related          => {}
      }
    end

    it 'creates a configuration script source with appropriate role' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :create, :post)

      post(api_configuration_script_sources_url, :params => create_params)
      expect_multiple_action_result(1, :success => true, :task => true, :message => /Creating Configuration Script Source/)
    end

    it 'create a new configuration script source with manager_resource id' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :create, :post)
      create_params[:manager_resource] = { :id => manager.id }

      post(api_configuration_script_sources_url, :params => create_params)
      expect_multiple_action_result(1, :success => true, :task => true, :message => /Creating Configuration Script Source/)
    end

    it 'can create new configuration script sources in bulk' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :create, :post)

      post(api_configuration_script_sources_url, :params => { :resources => [create_params, create_params] })

      expect_multiple_action_result(2, :success => true, :task => true, :message => /Creating Configuration Script Source/)
    end

    it 'requires a manager_resource to be specified' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :create, :post)

      post(api_configuration_script_sources_url, :params => { :resources => [create_params.except(:manager_resource)] })

      expect(response).to have_http_status(:ok)
      expect_multiple_action_result(1, :success => false, :message => /Must specify a Provider/)
    end

    it 'requires a valid manager' do
      api_basic_authorize collection_action_identifier(:configuration_script_sources, :create, :post)
      create_params[:manager_resource] = { :href => api_user_url(nil, 10) }

      post(api_configuration_script_sources_url, :params => { :resources => [create_params] })

      expect_multiple_action_result(1, :success => false, :message => /Must specify a Provider/)
    end

    it 'forbids creation of new configuration script source without an appropriate role' do
      api_basic_authorize

      post(api_configuration_script_sources_url, :params => create_params)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /api/configuration_script_sources/:id' do
    it 'can delete a configuration_script_source with an appropriate role' do
      api_basic_authorize action_identifier(:configuration_script_sources, :delete, :resource_actions, :delete)

      delete(api_configuration_script_source_url(nil, config_script_src))

      expect(response).to have_http_status(:no_content)
    end

    it 'forbids configuration_script_source delete without an appropriate role' do
      api_basic_authorize

      delete(api_configuration_script_source_url(nil, config_script_src))

      expect(response).to have_http_status(:forbidden)
    end

    it 'will raise an error if the configuration_script_source does not exist' do
      api_basic_authorize action_identifier(:configuration_script_sources, :delete, :resource_actions, :delete)

      delete(api_configuration_script_source_url(nil, 999_999))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/configuration_script_sources/:id/configuration_script_payloads' do
    let(:payload) { FactoryBot.create(:configuration_script_payload) }

    before do
      config_script_src.configuration_script_payloads << payload
    end

    it 'forbids configuration_script_payload retrievel without an appropriate role' do
      api_basic_authorize

      get(api_configuration_script_source_configuration_script_payloads_url(nil, config_script_src))

      expect(response).to have_http_status(:forbidden)
    end

    it 'lists all configuration_script_payloads belonging to a configuration_script_source' do
      api_basic_authorize subcollection_action_identifier(:configuration_script_sources, :configuration_script_payloads, :read, :get)

      get(api_configuration_script_source_configuration_script_payloads_url(nil, config_script_src))

      expected = {
        'resources' => [
          {'href' => api_configuration_script_source_configuration_script_payload_url(nil, config_script_src, payload)}
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can filter on region_number' do
      api_basic_authorize subcollection_action_identifier(:configuration_script_sources, :configuration_script_payloads, :read, :get)

      get(
        api_configuration_script_source_configuration_script_payloads_url(nil, config_script_src),
        :params => { :filter => ["region_number=#{payload.region_number}"] }
      )

      expected = {
        'subcount'  => 1,
        'resources' => [
          {'href' => api_configuration_script_source_configuration_script_payload_url(nil, config_script_src, payload)}
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)

      get(
        api_configuration_script_source_configuration_script_payloads_url(nil, config_script_src),
        :params => { :filter => ["region_number=#{payload.region_number + 1}"] }
      )

      expected = {
        'subcount'  => 0,
        'resources' => []
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end
end
