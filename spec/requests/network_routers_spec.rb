RSpec.describe 'NetworkRouters API' do
  let(:ems) { FactoryBot.create(:ems_openstack) }
  let(:cloud_tenant) { FactoryBot.create(:cloud_tenant_openstack, :ext_management_system => ems) }

  describe 'GET /api/network_routers' do
    it 'lists all cloud subnets with an appropriate role' do
      network_router = FactoryBot.create(:network_router)
      api_basic_authorize collection_action_identifier(:network_routers, :read, :get)

      get(api_network_routers_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'network_routers',
        'resources' => [
          hash_including('href' => api_network_router_url(nil, network_router))
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'forbids access to cloud subnets without an appropriate role' do
      api_basic_authorize

      get(api_network_routers_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/network_routers/:id' do
    it 'will show a cloud subnet with an appropriate role' do
      network_router = FactoryBot.create(:network_router)
      api_basic_authorize action_identifier(:network_routers, :read, :resource_actions, :get)

      get(api_network_router_url(nil, network_router))

      expect(response.parsed_body).to include('href' => api_network_router_url(nil, network_router))
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to a cloud tenant without an appropriate role' do
      network_router = FactoryBot.create(:network_router)
      api_basic_authorize

      get(api_network_router_url(nil, network_router))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/network_routers' do
    it 'forbids access to network routers without an appropriate role' do
      api_basic_authorize

      post(api_network_routers_url, :params => gen_request(:query, ""))

      expect(response).to have_http_status(:forbidden)
    end

    it "queues the creating of network router" do
      api_basic_authorize collection_action_identifier(:network_routers, :create)

      request = {
        "action"   => "create",
        "resource" => {
          "ems_id" => ems.network_manager.id,
          "name"   => "test_network_router"
        }
      }

      post(api_network_routers_url, :params => request)

      expect_multiple_action_result(1, :success => true, :message => "Creating Network Router test_network_router for Provider: #{ems.name}", :task => true)
    end

    it "raises error when provider does not support creating of network routers" do
      api_basic_authorize collection_action_identifier(:network_routers, :create)
      ems = FactoryBot.create(:ems_amazon, :name => 'test_provider')
      request = {
        "action"   => "create",
        "resource" => {
          "ems_id" => ems.network_manager.id,
          "name"   => "test_network_router"
        }
      }

      post(api_network_routers_url, :params => request)

      expected = {
        "success" => false,
        "message" => a_string_including("Create network router for Provider #{ems.name}")
      }
      expect(response.parsed_body["results"].first).to include(expected)
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /api/network_routers/:id" do
    let(:network_router) { FactoryBot.create(:network_router_openstack, :ext_management_system => ems.network_manager, :cloud_tenant => cloud_tenant) }

    it "can queue the updating of a network router" do
      api_basic_authorize(action_identifier(:network_routers, :edit))

      post(api_network_router_url(nil, network_router), :params => {:action => 'edit', :status => "inactive"})

      expected = {
        'success'   => true,
        'message'   => a_string_including('Updating Network Router'),
        'task_href' => a_string_matching(api_tasks_url),
        'task_id'   => a_kind_of(String)
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it "can't queue the updating of a network router unless authorized" do
      api_basic_authorize

      post(api_network_router_url(nil, network_router), :params => {:action => 'edit', :status => "inactive"})
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/network_routers" do
    it "can delete a router" do
      network_router = FactoryBot.create(:network_router)
      api_basic_authorize(action_identifier(:network_routers, :delete))

      delete(api_network_router_url(nil, network_router))

      expect(response).to have_http_status(:no_content)
    end
  end

  it "will not delete a router unless authorized" do
    network_router = FactoryBot.create(:network_router)
    api_basic_authorize

    delete(api_network_router_url(nil, network_router))

    expect(response).to have_http_status(:forbidden)
  end

  describe "POST /api/network_routers with delete action" do
    it "can delete a router" do
      ems = FactoryBot.create(:ems_network)
      network_router = FactoryBot.create(:network_router_openstack, :ext_management_system => ems)
      api_basic_authorize(action_identifier(:network_routers, :delete, :resource_actions))

      post(api_network_router_url(nil, network_router), :params => gen_request(:delete))

      expected = {
        'success' => true,
        'message' => a_string_including('Deleting Network Router')
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it "will not delete a router unless authorized" do
      network_router = FactoryBot.create(:network_router)
      api_basic_authorize

      post(api_network_router_url(nil, network_router), :params => {:action => "delete"})

      expect(response).to have_http_status(:forbidden)
    end

    it "can delete multiple network_routers" do
      ems = FactoryBot.create(:ems_network)
      network_router1, network_router2 = FactoryBot.create_list(:network_router_openstack, 2, :ext_management_system => ems)
      api_basic_authorize(action_identifier(:network_routers, :delete, :resource_actions))

      post(api_network_routers_url, :params => { :action => "delete", :resources => [{:id => network_router1.id},
                                                                                     {:id => network_router2.id}] })

      expect(response).to have_http_status(:ok)
    end

    it "forbids multiple network router deletion without an appropriate role" do
      network_router1, network_router2 = FactoryBot.create_list(:network_router, 2)
      api_basic_authorize

      post(api_network_routers_url, :params => { :action => "delete", :resources => [{:id => network_router1.id},
                                                                                     {:id => network_router2.id}] })

      expect(response).to have_http_status(:forbidden)
    end

    it 'raises an error when delete not supported for network router' do
      network_router = FactoryBot.create(:network_router)
      api_basic_authorize(action_identifier(:network_routers, :delete, :resource_actions))

      post(api_network_router_url(nil, network_router), :params => gen_request(:delete))

      expected = {
        'success' => false,
        'message' => a_string_including('Delete not supported for Network Router')
      }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to include(expected)
    end
  end
end
