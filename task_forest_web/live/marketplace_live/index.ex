defmodule TaskForestWeb.MarketplaceLive.Index do
  use TaskForestWeb, :live_view

  alias TaskForest.Accounts
  alias TaskForest.Providers
  alias TaskForest.WorkflowTemplates

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:categories, nil)
      |> assign(:providers_by_slug, nil)
      |> assign(:main_collections, nil)
      |> assign(:collections, nil)
      |> assign(:workflow_templates, nil)
      |> assign(:page_data, nil)
      |> assign(:search_params, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(
        params,
        _url,
        %{assigns: %{live_action: :search}} = socket
      ) do
    search_term = params["search_term"]

    socket =
      if search_term != nil do
        providers_by_slug = Providers.get_providers_mapped_by_slug()

        page_data = %{
          title: "Search: \"#{search_term}\""
        }

        # TODO: add pagination buttons to pages and add to url
        opts = [
          page_size: params["page_size"],
          page: params["page"]
        ]

        filters = %{
          search_term: search_term
        }

        workflow_templates = WorkflowTemplates.filter_workflow_templates(filters, opts)

        routes = [
          %{href: "/market", label: "Market", icon: "fa-solid:store"},
          %{
            href: "/market/search",
            label: "Search Results",
            active: true,
            icon: "bitcoin-icons:search-outline"
          }
        ]

        socket
        |> assign(:page_title, "Search: \"#{search_term}\"")
        |> assign(:page_data, page_data)
        |> assign(:providers_by_slug, providers_by_slug)
        |> assign(:workflow_templates, workflow_templates)
        |> assign(:routes, routes)
      else
        socket
        |> redirect(to: "/market")
      end

    {:noreply, socket}
  end

  def handle_params(
        %{"slug" => slug} = params,
        _url,
        %{assigns: %{live_action: :by_collection}} = socket
      ) do
    providers_by_slug = Providers.get_providers_mapped_by_slug()

    collection = WorkflowTemplates.get_collection_by_slug(slug)

    page_data = %{
      title: collection.title,
      short_description: collection.short_description,
      image_url: collection.image_url,
      markdown_description: collection.markdown_description,
      slug: collection.slug
    }

    # TODO: add pagination buttons to pages and add to url
    opts = [
      page_size: params["page_size"],
      page: params["page"]
    ]

    filters = %{
      collection: collection.id
    }

    workflow_templates = WorkflowTemplates.filter_workflow_templates(filters, opts)

    routes = [
      %{href: "/market", label: "Market", icon: "fa-solid:store"},
      %{
        href: "/market/collections/#{slug}",
        label: collection.title,
        active: true,
        icon: "material-symbols:collections-bookmark-rounded"
      }
    ]

    socket =
      socket
      |> assign(:page_title, collection.title)
      |> assign(:page_data, page_data)
      |> assign(:providers_by_slug, providers_by_slug)
      |> assign(:workflow_templates, workflow_templates)
      |> assign(:routes, routes)

    {:noreply, socket}
  end

  def handle_params(
        %{"slug" => slug} = params,
        _url,
        %{assigns: %{live_action: :by_provider}} = socket
      ) do
    providers_by_slug = Providers.get_providers_mapped_by_slug()

    provider = providers_by_slug[slug]

    page_data = %{
      title: provider.name,
      slug: provider.slug
    }

    # TODO: add pagination buttons to pages and add to url
    opts = [
      page_size: params["page_size"],
      page: params["page"]
    ]

    filters = %{
      provider: slug
    }

    workflow_templates = WorkflowTemplates.filter_workflow_templates(filters, opts)

    routes = [
      %{href: "/market", label: "Market", icon: "fa-solid:store"},
      %{
        href: "/market/providers/#{slug}",
        label: provider.name,
        active: true,
        icon: "mdi:puzzle"
      }
    ]

    socket =
      socket
      |> assign(:page_title, provider.name)
      |> assign(:page_data, page_data)
      |> assign(:providers_by_slug, providers_by_slug)
      |> assign(:workflow_templates, workflow_templates)
      |> assign(:routes, routes)

    {:noreply, socket}
  end

  def handle_params(
        %{"slug" => slug} = params,
        _url,
        %{assigns: %{live_action: :by_category}} = socket
      ) do
    providers_by_slug = Providers.get_providers_mapped_by_slug()

    category = WorkflowTemplates.get_category_by_slug(slug)

    page_data = %{
      title: category.name,
      slug: category.slug
    }

    # TODO: add pagination buttons to pages and add to url
    opts = [
      page_size: params["page_size"],
      page: params["page"]
    ]

    filters = %{
      selected_category_ids: [category.id]
    }

    workflow_templates = WorkflowTemplates.filter_workflow_templates(filters, opts)

    routes = [
      %{href: "/market", label: "Market", icon: "fa-solid:store"},
      %{
        href: "/market/categories/#{slug}",
        label: category.name,
        active: true,
        icon: category.icon
      }
    ]

    socket =
      socket
      |> assign(:page_title, category.name)
      |> assign(:page_data, page_data)
      |> assign(:providers_by_slug, providers_by_slug)
      |> assign(:workflow_templates, workflow_templates)
      |> assign(:routes, routes)

    {:noreply, socket}
  end

  def handle_params(_params, _url, socket) do
    categories = WorkflowTemplates.get_all_categories()

    workflow_templates = WorkflowTemplates.filter_workflow_templates()

    providers_by_slug = Providers.get_providers_mapped_by_slug()

    %{main_collections: main_collections, collections: collections} =
      WorkflowTemplates.get_collections()

    socket =
      socket
      |> assign(:page_title, "Market")
      |> assign(:categories, categories)
      |> assign(:providers_by_slug, providers_by_slug)
      |> assign(:main_collections, main_collections)
      |> assign(:collections, collections)
      |> assign(:workflow_templates, workflow_templates)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "react.search",
        params,
        socket
      ) do
    encoded_params = URI.encode_query(params)

    socket =
      socket
      |> assign(:search_params, params)
      |> redirect(to: "/market/search?#{encoded_params}")

    {:noreply, socket}
  end

  def handle_event(
        "react.switch_organization",
        %{"new_active_company_slug" => new_active_company_slug} = _params,
        %{
          assigns: %{
            user_id: user_id,
            user_companies: user_companies
          }
        } = socket
      ) do
    Accounts.update_user_active_company(user_id, new_active_company_slug)

    active_company = Enum.find(user_companies, &(new_active_company_slug == &1.slug))

    socket =
      socket
      |> assign(:active_company, active_company)
      |> assign(:company, active_company)
      |> put_flash(:info, "Switched to #{active_company.name}")
      |> push_event("server.switch_organization", %{
        new_active_company: active_company
      })

    {:noreply, socket}
  end
end
