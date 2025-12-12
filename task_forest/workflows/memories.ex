defmodule TaskForest.Workflows.Memories do
  import Ecto.Query

  alias TaskForest.Repo
  alias TaskForest.Workflows.Memory

  def store_memory(memory_params, memory \\ %Memory{}) do
    memory
    |> Memory.changeset(memory_params)
    |> Repo.insert_or_update()
  end

  # data_queries = %{"data.user_id": "1234", "data.task_id": "5678"}
  def retrieve_memories(workflow_id, data_queries) do
    filters =
      Enum.map(data_queries, fn {data_jsonpath, query_value} ->
        dynamic([memory], fragment("? ->> ? = ?", memory.data, ^data_jsonpath, ^query_value))
      end)

    query =
      Memory
      |> where([m], m.workflow_id == ^workflow_id)
      |> then(fn partial_query ->
        Enum.reduce(filters, partial_query, fn filter, query -> query |> where(^filter) end)
      end)
      |> order_by([m], desc: m.inserted_at)

    Repo.all(query)
  end
end
