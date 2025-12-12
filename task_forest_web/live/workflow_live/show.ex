defmodule TaskForestWeb.WorkflowLive.Show do
  use TaskForestWeb, :live_view

  alias TaskForest.Accounts
  alias TaskForest.Utils
  alias TaskForest.Workflows
  alias TaskForest.Workflows.Triggers

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event(
        "react.execute_workflow",
        %{"workflow_id" => workflow_id, "inputs" => inputs} = _params,
        socket
      ) do
    pid = self()

    socket =
      case Workflows.execute_workflow(workflow_id, inputs, %{notify_to: pid}) do
        {:ok, execution_id} ->
          push_event(socket, "server.workflow_update", %{
            execution_id: execution_id,
            status: "started"
          })

        {:error, :not_enough_credits} ->
          put_flash(socket, :error, "Not enough credits to execute the workflow")

        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.update_scheduled_trigger_status",
        %{
          "id" => id,
          "active" => active
        },
        socket
      ) do
    params = %{
      "id" => id,
      "active" => active
    }

    socket =
      with {:ok, updated_scheduled_trigger} <- Triggers.update_scheduled_trigger(params) do
        socket
        |> push_event("server.scheduled_trigger_updated", updated_scheduled_trigger)
        |> put_flash(:info, "Scheduled trigger updated successfully")
      else
        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.update_scheduled_trigger",
        %{
          "id" => id,
          "name" => name,
          "cron_expression" => cron_expression,
          "inputs" => inputs,
          "active" => active
        },
        socket
      ) do
    params = %{
      "id" => id,
      "name" => name,
      "cron_expression" => cron_expression,
      "inputs" => inputs,
      "active" => active
    }

    socket =
      with {:ok, _} <- Utils.validate_cron_expression(cron_expression),
           {:ok, updated_scheduled_trigger} <- Triggers.update_scheduled_trigger(params) do
        socket
        |> push_event("server.scheduled_trigger_updated", updated_scheduled_trigger)
        |> put_flash(:info, "Scheduled trigger updated successfully")
      else
        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.delete_scheduled_trigger",
        %{"scheduled_trigger_id" => scheduled_trigger_id},
        socket
      ) do
    socket =
      case Triggers.delete_scheduled_trigger(scheduled_trigger_id) do
        :ok ->
          socket
          |> push_event("server.scheduled_trigger_deleted", %{
            scheduled_trigger_id: scheduled_trigger_id
          })
          |> put_flash(:info, "Scheduled trigger deleted successfully")

        {:error, _} ->
          put_flash(socket, :error, "Failed to delete scheduled trigger")
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.create_scheduled_trigger",
        %{"cron_expression" => cron_expression, "name" => name, "inputs" => inputs},
        socket
      ) do
    params = %{
      name: name,
      cron_expression: cron_expression,
      inputs: inputs,
      active: true,
      workflow_id: socket.assigns.workflow.id
    }

    socket =
      with {:ok, _} <- Utils.validate_cron_expression(cron_expression),
           {:ok, scheduled_trigger} <- Triggers.create_scheduled_trigger(params) do
        socket
        |> push_event("server.scheduled_trigger_created", scheduled_trigger)
        |> put_flash(:info, "Scheduled trigger created successfully")
      else
        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event("react.retrieve_executions", %{"workflow_id" => workflow_id} = params, socket) do
    page_size = params["page_size"] || 5
    page = params["page"] || 1

    socket =
      case Workflows.get_executions(workflow_id,
             page: page,
             page_size: page_size
           ) do
        executions ->
          socket
          |> push_event("server.executions_retrieved", %{
            executions: executions,
            page: page,
            page_size: page_size
          })
          |> assign(:executions, executions)

        _ ->
          put_flash(socket, :error, "Failed to retrieve executions")
      end

    {:noreply, socket}
  end

  def handle_event("react.retrieve_execution", %{"execution_id" => execution_id}, socket) do
    socket =
      case Workflows.get_execution_by_id(execution_id) do
        {:ok, execution} ->
          socket
          |> push_event("server.execution_retrieved", %{
            execution: execution
          })

        {:error, _} ->
          put_flash(socket, :error, "Failed to retrieve execution")
      end

    {:noreply, socket}
  end

  def handle_event(
        "react.dashboard_repeat_execution",
        %{"execution_id" => execution_id} = _params,
        socket
      ) do
    pid = self()

    socket =
      case Workflows.repeat_execution(execution_id, %{notify_to: pid}) do
        {:ok, new_execution} ->
          socket
          |> put_flash(:info, "You started a new execution based on the previous one.")
          |> push_event("server.execution_update", %{
            execution: new_execution,
            status: "started"
          })

        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event("react.dashboard_cancel_execution", %{"execution_id" => execution_id}, socket) do
    outputs = %{
      error: "Execution cancelled by user"
    }

    socket =
      case Workflows.mark_execution_as_cancelled(execution_id, outputs) do
        {:ok, execution} ->
          socket
          |> put_flash(:info, "You have cancelled the execution.")
          |> push_event("server.execution_update", %{
            execution: execution,
            status: "cancelled"
          })

        {:error, _} ->
          put_flash(socket, :error, "Failed to cancel execution")
      end

    {:noreply, socket}
  end

  def handle_event("react.cancel_execution", %{"execution_id" => execution_id}, socket) do
    outputs = %{
      error: "Execution cancelled by user"
    }

    socket =
      case Workflows.mark_execution_as_cancelled(execution_id, outputs) do
        {:ok, _} ->
          push_event(socket, "server.workflow_update", %{
            execution_id: execution_id,
            status: "cancelled",
            outputs: outputs
          })

        {:error, _} ->
          put_flash(socket, :error, "Failed to cancel execution")
      end

    {:noreply, socket}
  end

  def handle_event("react.update_workflow", %{"workflow_id" => workflow_id} = params, socket) do
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
        "react.update_workflow_json",
        %{"workflow_id" => workflow_id, "type" => json_type, "json" => json} = _params,
        socket
      ) do
    params = Map.put(%{}, json_type, json)

    socket =
      case Workflows.update_workflow(workflow_id, params) do
        {:ok, workflow} ->
          assign(socket, :workflow, workflow)

        {:error, error_msg} ->
          put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event("react.generate_auth_token", _params, %{assigns: %{active_company: active_company}} = socket) do
    auth_token = Accounts.generate_auth_token() |> Accounts.store_auth_token(active_company.slug)

    socket =
      socket
      |> assign(:company_auth_token, auth_token)
      |> push_event("server.update_company_auth_token", %{
        company_auth_token: auth_token
      })

    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"workflow_id" => workflow_id}, _, socket) do
    live_action = socket.assigns.live_action

    socket =
      case Workflows.get_workflow_with_tasks(workflow_id) do
        {:ok, %{workflow: workflow, tasks: tasks, task_templates: _task_templates}} ->
          company = Accounts.get_company(workflow.company_id)

          company_auth_token =
            with :api_documentation <- live_action,
                 company_auth_token <- Accounts.retrieve_company_auth_token(company.slug),
                 false <- is_nil(company_auth_token) do
              company_auth_token
            else
              _ ->
                "AUTH_TOKEN"
            end

          # TODO - move this to config
          api_endpoint = "https://app.plomb.ai/v1/#{company.slug}/#{workflow.id}"

          can_run_workflow = length(tasks) > 0

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

          recent_executions =
            if live_action == :app_dashboard do
              Workflows.get_executions(workflow_id, page_size: 5)
            else
              []
            end

          scheduled_triggers = Triggers.get_workflow_scheduled_triggers(workflow_id)

          workflow_stats =
            if live_action == :app_dashboard do
              Workflows.get_workflow_stats(workflow_id)
            else
              []
            end

          routes =
            case live_action do
              :api_documentation ->
                [
                  %{href: "/home", label: "Home", icon: "mingcute:home-7-fill"},
                  %{
                    href: "/workflows/#{workflow.id}",
                    label: workflow.name,
                    icon: "streamline-ultimate:workflow-exit-door-bold"
                  },
                  %{
                    href: "/workflows/#{workflow_id}/app-dashboard",
                    label: "Workflow Dashboard",
                    icon: "ix:dashboard-filled"
                  },
                  %{
                    href: "/workflows/#{workflow_id}/api-documentation",
                    label: "API Documentation",
                    active: true,
                    icon: "ant-design:api-filled"
                  }
                ]

              _ ->
                [
                  %{href: "/home", label: "Home", icon: "mingcute:home-7-fill"},
                  %{
                    href: "/workflows/#{workflow.id}",
                    label: workflow.name,
                    icon: "streamline-ultimate:workflow-exit-door-bold"
                  },
                  %{
                    href: "/workflows/#{workflow_id}/app-dashboard",
                    label: "Workflow Dashboard",
                    active: true,
                    icon: "ix:dashboard-filled"
                  }
                ]
            end

          shortcuts =
            case live_action do
              :api_documentation ->
                [
                  %{
                    name: "API Keys",
                    description: "Manage your organization API keys for Plomb.",
                    icon: "material-symbols:key-outline-rounded",
                    link: "/api-keys"
                  }
                ]

              _ ->
                [
                  %{
                    name: "API Documentation",
                    description: "Documentation to integrate this workflow through its HTTP API.",
                    icon: "ant-design:api-outlined",
                    link: "/workflows/#{workflow.id}/api-documentation"
                  },
                  %{
                    name: "Magic Forms",
                    description: "Shareable forms to run this workflow you can customize.",
                    icon: "tabler:input-spark",
                    link: "/workflows/#{workflow.id}/magic-forms"
                  }
                  # %{
                  #   name: "Workflow Template",
                  #   description: "Share this workflow with other Plomb users.",  # TODO: Polish this feature before enabling
                  #   icon: "fluent-mdl2:file-template",
                  #   link: "/"
                  # }
                ]
            end

          socket
          |> assign(:page_title, page_title(socket.assigns.live_action))
          |> assign(:workflow, workflow)
          |> assign(:shortcuts, shortcuts)
          |> assign(:company, company)
          |> assign(:tasks, tasks)
          |> assign(:executions, recent_executions)
          |> assign(:workflow_stats, workflow_stats)
          |> assign(:routes, routes)
          |> assign(:can_run_workflow, can_run_workflow)
          |> assign(:scheduled_triggers, scheduled_triggers)
          |> assign(:allow_org_switch, false)
          |> assign(:company_auth_token, company_auth_token)

        {:error, _error} ->
          put_flash(socket, :error, "Failed to load workflow")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:workflow_completed, data}, socket) do
    {:ok, execution} = Workflows.get_execution_by_id(data.execution_id)

    socket =
      socket
      |> push_event("server.workflow_update", %{
        execution_id: data.execution_id,
        status: "completed",
        outputs: data.outputs
      })
      |> push_event("server.execution_update", %{
        execution: execution,
        status: "completed"
      })

    {:noreply, socket}
  end

  def handle_info({:workflow_cancelled, data}, socket) do
    {:ok, execution} = Workflows.get_execution_by_id(data.execution_id)

    socket =
      socket
      |> push_event("server.workflow_update", %{
        execution_id: data.execution_id,
        status: "cancelled",
        outputs: data.outputs
      })
      |> push_event("server.execution_update", %{
        execution: execution,
        status: "cancelled"
      })

    {:noreply, socket}
  end

  def handle_info({:task_error, data}, socket) do
    {:ok, execution} = Workflows.get_execution_by_id(data.execution_id)

    socket =
      socket
      |> push_event("server.workflow_update", %{
        execution_id: data.execution_id,
        status: "delayed",
        outputs: data.outputs
      })
      |> push_event("server.execution_update", %{
        execution: execution,
        status: "delayed"
      })

    {:noreply, socket}
  end

  defp page_title(:show), do: "Workflow"
  defp page_title(:api_documentation), do: "API Documentation"
  defp page_title(:app_dashboard), do: "App Dashboard"
end
