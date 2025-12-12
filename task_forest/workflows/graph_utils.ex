defmodule TaskForest.Workflows.GraphUtils do
  def get_task_dependencies(task_id, graph) do
    Graph.reaching_neighbors(graph, [task_id])
  end

  def get_iterator_variables(raw_graph) do
    iterator_prefix = "iter_"

    raw_graph["steps"]
    |> Enum.reduce([], fn %{"t" => node_name}, acc ->
      if String.starts_with?(node_name, iterator_prefix) do
        variable = String.replace(node_name, iterator_prefix, "")
        [variable | acc]
      else
        acc
      end
    end)
  end

  def get_tasks_with_convergers(graph) do
    graph
    |> Graph.postorder()
    |> Enum.reverse()
  end

  def get_next_tasks(task_id, graph) do
    Graph.out_neighbors(graph, task_id)
  end

  def get_previous_tasks(task_id, graph) do
    Graph.in_neighbors(graph, task_id)
  end

  def get_convergers(graph) do
    graph
    |> Graph.vertices()
    |> Enum.filter(fn vertex -> String.starts_with?(vertex, "converger_") end)
  end

  def get_last_node(raw_graph) do
    reversed_tasks =
      raw_graph
      |> load_graph()
      |> Graph.postorder()

    if reversed_tasks == [] do
      nil
    else
      Kernel.hd(reversed_tasks)
    end
  end

  def get_start_nodes(graph) do
    graph
    |> Graph.vertices()
    |> Enum.filter(fn node ->
      Graph.in_degree(graph, node) == 0
    end)
  end

  def get_end_nodes(raw_graph) do
    graph = load_graph(raw_graph)

    graph
    |> Graph.vertices()
    |> Enum.filter(fn node ->
      Graph.out_degree(graph, node) == 0
    end)
  end

  def is_node_iteration_instance?(_graph, _node_id, nil), do: false

  def is_node_iteration_instance?(graph, node_id, iterable_key) do
    iterator_id = "iter_" <> iterable_key

    converger_id =
      graph
      |> Graph.vertices()
      |> Enum.find(fn node_id -> String.starts_with?(node_id, "converger_") end)

    has_iterator? = Graph.has_vertex?(graph, iterator_id)
    has_converger? = Graph.has_vertex?(graph, converger_id)

    cond do
      has_iterator? and has_converger? ->
        case Graph.get_paths(graph, iterator_id, converger_id) do
          paths when is_list(paths) ->
            Enum.any?(paths, fn path ->
              inner_path = Enum.reject(path, fn node_id -> node_id in [iterator_id, converger_id] end)
              node_id in inner_path
            end)

          _ ->
            false
        end

      has_iterator? and not has_converger? ->
        reachable = Graph.reachable_neighbors(graph, [iterator_id])
        node_id in reachable

      true ->
        false
    end
  end

  def get_iteration_section_nodes_without_nested_iterations(graph, iteration_key) do
    iterator_id = "iter_" <> iteration_key
    converger_id = "converger_" <> iteration_key

    found_nodes =
      with paths <- Graph.get_paths(graph, iterator_id, converger_id),
           node_ids <- Enum.flat_map(paths, & &1),
           unique_node_ids <- Enum.uniq(node_ids) do
        Enum.reject(unique_node_ids, fn node_id ->
          Enum.member?([iterator_id, converger_id], node_id)
        end)
      else
        _ -> []
      end

    first_found_nested_iterator =
      Enum.find(found_nodes, fn node_id ->
        String.starts_with?(node_id, "iter")
      end)

    if first_found_nested_iterator do
      [_prefix, nested_iteration_key] = String.split(first_found_nested_iterator, "_", parts: 2)

      nested_nodes = get_iteration_section_nodes_without_nested_iterations(graph, nested_iteration_key)

      found_nodes
      |> MapSet.new()
      |> MapSet.difference(MapSet.new(nested_nodes))
      |> MapSet.to_list()
    else
      found_nodes
    end
  end

  def get_next_nodes(raw_graph, node_id) do
    raw_graph
    |> load_graph()
    |> Graph.out_neighbors(node_id)
  end

  def add_appending_task_to_raw_graph(%{"tasks" => []} = raw_graph, task_id) do
    add_task_to_raw_graph(raw_graph, task_id)
  end

  def add_appending_task_to_raw_graph(raw_graph, task_id) do
    last_node = get_last_node(raw_graph)

    raw_graph
    |> add_task_to_raw_graph(task_id)
    |> add_step_to_raw_graph(%{"s" => last_node, "t" => task_id})
  end

  # TODO: support adding an iterator to an empty graph
  def add_appending_converger_to_raw_graph(%{"tasks" => []} = raw_graph, _converger_id) do
    raw_graph
  end

  def add_appending_special_node_to_raw_graph(raw_graph, node_id) do
    last_node = get_last_node(raw_graph)

    if last_node != nil do
      add_step_to_raw_graph(raw_graph, %{"s" => last_node, "t" => node_id})
    else
      raw_graph
    end
  end

  def add_task_to_raw_graph(raw_graph, task_id) do
    Map.merge(raw_graph, %{
      "tasks" => raw_graph["tasks"] ++ [task_id]
    })
  end

  def add_step_to_raw_graph(raw_graph, step) do
    Map.merge(raw_graph, %{
      "steps" => raw_graph["steps"] ++ [step]
    })
  end

  def remove_step_from_raw_graph(raw_graph, step) do
    updated_steps = raw_graph["steps"] |> Enum.reject(fn s -> s == step end)

    Map.merge(raw_graph, %{
      "steps" => updated_steps
    })
  end

  def remove_iterator_from_raw_graph(raw_graph, iterator_id) do
    updated_steps =
      raw_graph["steps"]
      |> Enum.reject(fn %{"s" => s, "t" => t} -> s == iterator_id or t == iterator_id end)

    Map.merge(raw_graph, %{
      "steps" => updated_steps
    })
  end

  def remove_converger_from_raw_graph(raw_graph, converger_id) do
    updated_steps =
      raw_graph["steps"]
      |> Enum.reject(fn %{"s" => s, "t" => t} -> s == converger_id or t == converger_id end)

    Map.merge(raw_graph, %{
      "steps" => updated_steps
    })
  end

  def remove_task_from_raw_graph(raw_graph, task_id) do
    updated_steps =
      raw_graph["steps"]
      |> Enum.reject(fn %{"s" => s, "t" => t} -> s == task_id or t == task_id end)

    updated_tasks = raw_graph["tasks"] |> Enum.reject(fn t -> t == task_id end)

    Map.merge(raw_graph, %{
      "steps" => updated_steps,
      "tasks" => updated_tasks
    })
  end

  def add_filter_to_raw_graph(raw_graph, filter) do
    existing_filters = raw_graph["filters"] || %{}

    filter_id = "#{filter["source"]}-#{filter["target"]}"

    updated_filters = Map.put(existing_filters, filter_id, filter)

    Map.merge(
      raw_graph,
      %{
        "filters" => updated_filters
      }
    )
  end

  def remove_filter_from_raw_graph(raw_graph, %{"source" => source, "target" => target} = _filter) do
    existing_filters = raw_graph["filters"] || %{}

    filter_id = "#{source}-#{target}"

    updated_filters = Map.drop(existing_filters, [filter_id])

    Map.merge(
      raw_graph,
      %{
        "filters" => updated_filters
      }
    )
  end

  def load_graph(%{"tasks" => tasks, "steps" => steps} = _raw_graph) do
    edges = Enum.map(steps, fn %{"s" => source, "t" => target} -> {source, target} end)

    Graph.new()
    |> Graph.add_vertices(tasks)
    |> Graph.add_edges(edges)
  end

  def load_graph(%Oban.Pro.Workers.Workflow{changesets: changesets} = _oban_workflow) do
    changesets
    |> Enum.map(&{&1.changes.meta.name, &1.changes.meta.deps})
    |> Enum.reduce(Graph.new(), fn {name, deps}, graph ->
      graph
      |> Graph.add_vertex(name)
      |> Graph.add_edges(for dep <- deps, do: {dep, name})
    end)
  end

  def to_dot(graph) do
    {:ok, dot_graph} = Graph.to_dot(graph)

    dot_graph
  end

  def remap_graph_tasks(graph, new_tasks) do
    changes =
      new_tasks
      |> Enum.map(fn task ->
        {task.template_reference_for_id, task.id}
      end)
      |> Map.new()

    new_steps =
      Enum.map(graph["steps"], fn %{"s" => source, "t" => target} ->
        update_fn = fn task_id ->
          if String.starts_with?(task_id, "iter") || String.starts_with?(task_id, "converger") do
            task_id
          else
            changes[task_id]
          end
        end

        %{
          "s" => update_fn.(source),
          "t" => update_fn.(target)
        }
      end)

    # TODO: handle filters after implementing workflow_task_ids

    new_tasks = Enum.map(graph["tasks"], &changes[&1])

    %{
      "steps" => new_steps,
      "tasks" => new_tasks
    }
  end
end
