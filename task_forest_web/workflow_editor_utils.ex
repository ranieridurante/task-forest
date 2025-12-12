defmodule TaskForestWeb.WorkflowEditorUtils do
  alias TaskForest.Workflows.GraphUtils

  @default_task_style %{
    background_color: "bg-white",
    text_color: "text-sky-500",
    icon_color: "text-sky-500",
    border_color: "border-l-sky-500",
    icon: "lucide:cog"
  }

  def build_nodes(raw_graph, tasks, task_templates, workflow_id) do
    tasks
    |> Enum.map_reduce(0, fn task, acc ->
      task_template = task_templates[task.task_template_id]

      {
        build_task_node(task, task_template, workflow_id, %{x: 0, y: acc}),
        acc + 200
      }
    end)
    |> then(fn {nodes, _} -> nodes end)
    |> Enum.concat(build_converger_nodes(raw_graph["steps"], workflow_id))
    |> Enum.concat(build_iterator_nodes(raw_graph["steps"], workflow_id))
  end

  def build_node_change("add_converger", converger_data) do
    [
      %{
        type: "add",
        item: build_converger_node(converger_data)
      }
    ]
  end

  def build_node_change("add_iterable", iterable_data) do
    [
      %{
        type: "add",
        item: build_iterator_node(iterable_data)
      }
    ]
  end

  def build_node_change("remove", node_id) do
    [
      %{
        type: "remove",
        id: node_id
      }
    ]
  end

  def build_node_change("add_task", task, task_template, workflow_id) do
    [
      %{
        type: "add",
        item: build_task_node(task, task_template, workflow_id)
      }
    ]
  end

  def build_node_change("update", task, task_template, workflow_id) do
    [
      %{
        type: "remove",
        id: task.id
      },
      %{
        type: "add",
        item: build_task_node(task, task_template, workflow_id)
      }
    ]
  end

  def build_converger_node(converger_data, position \\ %{x: 10, y: 10}) do
    label = "Converger"

    %{
      id: converger_data.converger_id,
      position: position,
      type: "convergerNode",
      data: %{
        label: label,
        converger_id: converger_data.converger_id,
        workflow_id: converger_data.workflow_id,
        style: %{
          icon: "mdi:merge",
          background_color: "bg-plombPink-500"
        }
      }
    }
  end

  def build_iterator_node(iterator_data, position \\ %{x: 10, y: 10}) do
    iterable_key = String.replace(iterator_data.iterator_id, "iter_", "")

    %{
      id: iterator_data.iterator_id,
      position: position,
      type: "iteratorNode",
      data: %{
        id: iterator_data.iterator_id,
        label: "List Processor",
        iterable_key: iterable_key,
        workflow_id: iterator_data.workflow_id,
        style: %{
          icon: "mdi:repeat-variant",
          background_color: "bg-plombPink-500"
        }
      }
    }
  end

  def build_task_node(task, task_template, workflow_id, position \\ %{x: 10, y: 10}) do
    config = Map.merge(task_template.config, task.config_overrides || %{})

    inputs_definition =
      if task.inputs_definition != nil and task.inputs_definition != %{},
        do: task.inputs_definition,
        else: task_template.inputs_definition

    outputs_definition =
      if task.inputs_definition != nil and task.outputs_definition != %{},
        do: task.outputs_definition,
        else: task_template.outputs_definition

    %{
      id: task.id,
      position: position,
      type: "taskNode",
      data: %{
        task_id: task.id,
        task_template_id: task.task_template_id,
        label: task.name || task_template.name,
        workflow_id: workflow_id,
        description: task_template.description,
        inputs_definition: inputs_definition,
        outputs_definition: outputs_definition,
        task_config: config,
        style: task_template.style || @default_task_style
      }
    }
  end

  def build_edge_changes(event_name, graph, node_id)
      when event_name in ["iterator_created", "converger_created", "task_created"] do
    last_node = GraphUtils.get_last_node(graph)

    if last_node != nil do
      [
        %{
          type: "add",
          item: build_single_edge(last_node, node_id)
        }
      ]
    else
      []
    end
  end

  def build_edge_changes(event_name, %{"steps" => steps} = _graph, node_id)
      when event_name in ["iterator_removed", "converger_removed", "task_removed"] do
    steps
    |> Enum.filter(fn %{"s" => s, "t" => t} ->
      s == node_id or t == node_id
    end)
    |> Enum.map(fn %{"s" => s, "t" => t} ->
      edge_id = "#{s}-#{t}"

      %{
        type: "remove",
        id: edge_id
      }
    end)
  end

  def build_edge_changes("remove_filter", source, target) do
    [
      %{
        id: "#{source}-#{target}",
        type: "replace",
        item: build_single_edge(source, target)
      }
    ]
  end

  def build_edge_changes("step_created", %{"source" => source, "target" => target}) do
    [
      %{
        type: "add",
        item: build_single_edge(source, target)
      }
    ]
  end

  def build_edge_changes("step_removed", %{"source" => source, "target" => target}) do
    [
      %{
        type: "remove",
        id: "#{source}-#{target}"
      }
    ]
  end

  def build_edge_changes("add_filter", source, target, filter) do
    [
      %{
        id: "#{source}-#{target}",
        type: "replace",
        item: build_single_edge(source, target, %{filter: filter})
      }
    ]
  end

  @spec build_edges(atom() | %{:steps => any(), optional(any()) => any()}) :: list()
  def build_edges(raw_graph) do
    raw_graph["steps"]
    |> Enum.map(fn %{"s" => source, "t" => target} ->
      if source != nil and target != nil do
        filters = raw_graph["filters"] || %{}

        filter_id = "#{source}-#{target}"

        filter = filters[filter_id]

        data =
          if filter do
            %{filter: filter}
          else
            nil
          end

        build_single_edge(source, target, data)
      end
    end)
  end

  defp build_single_edge(source, target, data \\ %{}) do
    %{
      id: "#{source}-#{target}",
      type: "nodeConnection",
      source: source,
      target: target,
      data: data
    }
  end

  defp build_iterator_nodes(steps, workflow_id) do
    steps
    |> Enum.reduce([], fn %{"s" => source, "t" => target}, acc ->
      source = if source != nil and String.starts_with?(source, "iter_"), do: source
      target = if target != nil and String.starts_with?(target, "iter_"), do: target

      acc ++ [source || target]
    end)
    |> Enum.uniq()
    |> Enum.reject(&is_nil/1)
    |> Enum.map_reduce(0, fn iterator_id, acc ->
      {
        build_iterator_node(%{iterator_id: iterator_id, workflow_id: workflow_id}, %{
          x: acc,
          y: 100
        }),
        acc + 200
      }
    end)
    |> then(fn {nodes, _} -> nodes end)
  end

  defp build_converger_nodes(steps, workflow_id) do
    steps
    |> Enum.reduce([], fn %{"s" => source, "t" => target}, acc ->
      source = if source != nil and String.starts_with?(source, "converger_"), do: source, else: nil
      target = if target != nil and String.starts_with?(target, "converger_"), do: target, else: nil

      acc ++ [source, target]
    end)
    |> Enum.uniq()
    |> Enum.reject(&is_nil/1)
    |> Enum.map_reduce(0, fn converger_id, acc ->
      {
        build_converger_node(%{converger_id: converger_id, workflow_id: workflow_id}, %{x: acc, y: 100}),
        acc + 200
      }
    end)
    |> then(fn {nodes, _} -> nodes end)
  end
end
