defmodule TaskForestWeb.WorkflowLive.Editor do
  use TaskForestWeb, :live_view

  alias TaskForest.Accounts
  alias TaskForest.Providers
  alias TaskForest.Tasks
  alias TaskForest.Utils
  alias TaskForest.Workflows
  alias TaskForest.Workflows.GraphUtils
  alias TaskForestWeb.Layouts
  alias TaskForestWeb.WorkflowEditorUtils

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, layout: {Layouts, :editor}}
  end

  @impl true
  def handle_event(
        "react.update_task",
        %{"task_id" => task_id, "params" => task_params, "workflow_id" => workflow_id} = params,
        socket
      ) do
    formatted_inputs_definition = Utils.force_snake_case_keys(task_params["inputs_definition"])
    formatted_outputs_definition = Utils.force_snake_case_keys(task_params["outputs_definition"])

    params =
      params
      |> Map.merge(task_params)
      |> put_in(["inputs_definition"], formatted_inputs_definition)
      |> put_in(["outputs_definition"], formatted_outputs_definition)

    socket =
      case Workflows.update_task(task_id, params) do
        {:ok, %{updated_task: task, task_template: task_template}} ->
          node_changes =
            WorkflowEditorUtils.build_node_change("update", task, task_template, workflow_id)

          push_event(socket, "server.update_editor", %{
            changes: %{
              node_changes: node_changes
            }
          })

        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event("react.search_providers", %{"term" => term}, socket) do
    socket =
      case Providers.search_active_providers_by_name(term) do
        {:ok, providers} ->
          push_event(socket, "server.update_provider_search_results", %{
            providers: providers
          })

        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.get_provider_task_templates",
        %{"provider_slug" => provider_slug},
        socket
      ) do
    socket =
      with {:ok, task_templates} <- Tasks.get_task_templates_by_provider(provider_slug),
           {:ok, featured_task_templates} <-
             Tasks.get_featured_task_templates_by_provider(provider_slug) do
        push_event(socket, "server.update_provider_task_templates", %{
          task_templates: task_templates,
          featured_task_templates: featured_task_templates
        })
      else
        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.update_workflow_json",
        %{"workflow_id" => workflow_id, "type" => json_type, "json" => json} = _params,
        socket
      ) do
    formatted_json = Utils.force_snake_case_keys(json)

    params = Map.put(%{}, json_type, formatted_json)

    socket =
      case Workflows.update_workflow(workflow_id, params) do
        {:ok, workflow} ->
          assign(socket, :workflow, workflow)

        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.update_workflow",
        %{"workflow_id" => workflow_id} = params,
        %{assigns: %{routes: routes}} = socket
      ) do
    socket =
      case Workflows.update_workflow(workflow_id, params) do
        {:ok, workflow} ->
          routes =
            Enum.take(routes, length(routes) - 1) ++
              [
                %{
                  href: "/workflows/#{workflow_id}",
                  label: workflow.name,
                  active: true
                }
              ]

          socket
          |> assign(:routes, routes)
          |> assign(:workflow, workflow)

        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.create_iterator",
        %{"workflow_id" => workflow_id, "iterable_key" => iterable_key},
        socket
      ) do
    iterator_id = "iter_#{iterable_key}"

    node_data = %{
      iterator_id: iterator_id,
      workflow_id: workflow_id
    }

    socket =
      case Workflows.update_workflow_graph(
             workflow_id,
             iterator_id,
             &GraphUtils.add_appending_special_node_to_raw_graph/2
           ) do
        {:ok, %{workflow: original_workflow}} ->
          edge_changes =
            WorkflowEditorUtils.build_edge_changes(
              "iterator_created",
              original_workflow.graph,
              iterator_id
            )

          node_changes = WorkflowEditorUtils.build_node_change("add_iterable", node_data)

          push_event(socket, "server.update_editor", %{
            changes: %{
              node_changes: node_changes,
              edge_changes: edge_changes
            }
          })

        {:error, _error_msg} ->
          put_flash(socket, :error, "Failed to create iterator")
      end

    {:noreply, socket}
  end

  def handle_event("react.create_converger", %{"workflow_id" => workflow_id}, socket) do
    converger_id = "converger_#{:erlang.unique_integer([:positive])}"

    converger_data = %{
      converger_id: converger_id,
      workflow_id: workflow_id
    }

    socket =
      case Workflows.update_workflow_graph(
             workflow_id,
             converger_id,
             &GraphUtils.add_appending_special_node_to_raw_graph/2
           ) do
        {:ok, %{workflow: original_workflow}} ->
          node_changes = WorkflowEditorUtils.build_node_change("add_converger", converger_data)

          edge_changes =
            WorkflowEditorUtils.build_edge_changes(
              "converger_created",
              original_workflow.graph,
              converger_id
            )

          push_event(socket, "server.update_editor", %{
            changes: %{
              node_changes: node_changes,
              edge_changes: edge_changes
            }
          })

        {:error, _error_msg} ->
          put_flash(socket, :error, "Failed to create converger")
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.delete_iterator",
        %{"iterator_id" => iterator_id, "workflow_id" => workflow_id},
        socket
      ) do
    socket =
      with {:ok, %{original_graph: original_graph}} <-
             Workflows.delete_iterator(iterator_id, workflow_id) do
        node_changes = WorkflowEditorUtils.build_node_change("remove", iterator_id)

        edge_changes =
          WorkflowEditorUtils.build_edge_changes("iterator_removed", original_graph, iterator_id)

        push_event(socket, "server.update_editor", %{
          changes: %{
            node_changes: node_changes,
            edge_changes: edge_changes
          }
        })
      else
        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.delete_converger",
        %{"converger_id" => converger_id, "workflow_id" => workflow_id} = _params,
        socket
      ) do
    socket =
      with {:ok, %{original_graph: original_graph}} <-
             Workflows.delete_converger(converger_id, workflow_id) do
        node_changes = WorkflowEditorUtils.build_node_change("remove", converger_id)

        edge_changes =
          WorkflowEditorUtils.build_edge_changes("converger_removed", original_graph, converger_id)

        push_event(socket, "server.update_editor", %{
          changes: %{
            node_changes: node_changes,
            edge_changes: edge_changes
          }
        })
      else
        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.save_filter",
        %{
          "filter" =>
            %{
              "source" => source,
              "target" => target
            } = filter,
          "workflow_id" => workflow_id
        },
        socket
      ) do
    socket =
      with workflow <- Workflows.get_workflow_by_id(workflow_id),
           false <- is_nil(workflow),
           {:ok, _result} <- Workflows.update_workflow_graph(workflow_id, filter, &GraphUtils.add_filter_to_raw_graph/2) do
        edge_changes = WorkflowEditorUtils.build_edge_changes("add_filter", source, target, filter)

        push_event(socket, "server.update_editor", %{
          changes: %{
            edge_changes: edge_changes
          }
        })
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.delete_filter",
        %{
          "filter" =>
            %{
              "source" => source,
              "target" => target
            } = filter,
          "workflow_id" => workflow_id
        },
        socket
      ) do
    socket =
      with workflow <- Workflows.get_workflow_by_id(workflow_id),
           false <- is_nil(workflow),
           {:ok, _result} <-
             Workflows.update_workflow_graph(workflow_id, filter, &GraphUtils.remove_filter_from_raw_graph/2) do
        edge_changes = WorkflowEditorUtils.build_edge_changes("remove_filter", source, target)

        push_event(socket, "server.update_editor", %{
          changes: %{
            edge_changes: edge_changes
          }
        })
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.delete_task",
        %{"task_id" => task_id, "workflow_id" => workflow_id},
        socket
      ) do
    socket =
      with workflow <- Workflows.get_workflow_by_id(workflow_id),
           false <- is_nil(workflow),
           {:ok, task_id} <- Workflows.delete_task(task_id) do
        node_changes = WorkflowEditorUtils.build_node_change("remove", task_id)

        edge_changes =
          WorkflowEditorUtils.build_edge_changes("task_removed", workflow.graph, task_id)

        push_event(socket, "server.update_editor", %{
          changes: %{
            node_changes: node_changes,
            edge_changes: edge_changes
          }
        })
      else
        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.create_task",
        %{"params" => task_params, "workflow_id" => workflow_id} = params,
        socket
      ) do
    formatted_inputs_definition = Utils.force_snake_case_keys(task_params["inputs_definition"])
    formatted_outputs_definition = Utils.force_snake_case_keys(task_params["outputs_definition"])

    params =
      params
      |> Map.merge(task_params)
      |> put_in(["inputs_definition"], formatted_inputs_definition)
      |> put_in(["outputs_definition"], formatted_outputs_definition)

    socket =
      case Workflows.create_task(params) do
        {:ok,
         %{
           task: task,
           task_template: task_template,
           updated_workflow: workflow,
           workflow: previous_workflow
         }} ->
          edge_changes =
            WorkflowEditorUtils.build_edge_changes(
              "task_created",
              previous_workflow.graph,
              task.id
            )

          node_changes =
            WorkflowEditorUtils.build_node_change("add_task", task, task_template, workflow_id)

          socket
          |> push_event("server.update_editor", %{
            changes: %{
              node_changes: node_changes,
              edge_changes: edge_changes
            }
          })
          |> assign(:workflow, workflow)

        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.create_step",
        %{"workflow_id" => workflow_id, "source" => source, "target" => target} = params,
        socket
      ) do
    graph_update_fn = &GraphUtils.add_step_to_raw_graph/2

    Workflows.update_workflow_graph(
      workflow_id,
      %{
        "s" => source,
        "t" => target
      },
      graph_update_fn
    )

    edge_changes = WorkflowEditorUtils.build_edge_changes("step_created", params)

    socket =
      push_event(socket, "server.update_editor", %{
        changes: %{
          edge_changes: edge_changes
        }
      })

    {:noreply, socket}
  end

  def handle_event(
        "react.delete_step",
        %{"source" => source, "target" => target} = params,
        %{assigns: %{workflow: workflow}} = socket
      ) do
    graph_update_fn = &GraphUtils.remove_step_from_raw_graph/2

    Workflows.update_workflow_graph(
      workflow.id,
      %{
        "s" => source,
        "t" => target
      },
      graph_update_fn
    )

    edge_changes = WorkflowEditorUtils.build_edge_changes("step_removed", params)

    socket =
      push_event(socket, "server.update_editor", %{
        changes: %{
          edge_changes: edge_changes
        }
      })

    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"workflow_id" => "new"}, _, %{assigns: %{active_company: company}} = socket) do
    socket =
      case Workflows.create_workflow(%{"name" => "Untitled Workflow", "company_id" => company.id}) do
        {:ok, %{workflow: workflow}} ->
          redirect(socket, to: "/workflows/#{workflow.id}")

        {:error, _error} ->
          put_flash(socket, :error, "Failed to create workflow")
      end

    {:noreply, socket}
  end

  def handle_params(%{"workflow_id" => workflow_id}, _, socket) do
    socket =
      case Workflows.get_workflow_with_tasks(workflow_id) do
        {:ok, %{workflow: workflow, tasks: tasks, task_templates: task_templates}} ->
          initial_nodes =
            WorkflowEditorUtils.build_nodes(workflow.graph, tasks, task_templates, workflow_id)

          initial_edges = WorkflowEditorUtils.build_edges(workflow.graph)

          company = Accounts.get_company(workflow.company_id)

          # TODO - move this to config
          api_endpoint = "https://app.plomb.ai/v1/#{company.slug}/#{workflow.id}"

          workflow = %{
            id: workflow.id,
            company_id: workflow.company_id,
            name: workflow.name,
            description: workflow.description,
            config: workflow.config,
            inputs_definition: workflow.inputs_definition,
            outputs_definition: workflow.outputs_definition,
            api_endpoint: api_endpoint
          }

          recent_executions = Workflows.get_executions(workflow_id, page_size: 10)

          routes = []

          user_id = socket.assigns.user_id
          user_task_templates = Tasks.get_user_task_templates(user_id)

          active_providers = Providers.get_active_providers()
          featured_providers = Providers.get_featured_providers()

          socket
          |> assign(:page_title, page_title(socket.assigns.live_action))
          |> assign(:workflow, workflow)
          |> assign(:company, company)
          |> assign(:tasks, tasks)
          |> assign(:initial_nodes, initial_nodes)
          |> assign(:initial_edges, initial_edges)
          |> assign(:recent_executions, recent_executions)
          |> assign(:routes, routes)
          |> assign(:user_task_templates, user_task_templates)
          |> assign(:active_providers, active_providers)
          |> assign(:featured_providers, featured_providers)

        {:error, _error} ->
          put_flash(socket, :error, "Failed to load workflow")
      end

    {:noreply, socket}
  end

  defp page_title(:editor), do: "Workflow Editor"
end
