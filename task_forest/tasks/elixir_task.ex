defmodule TaskForest.Tasks.ElixirTask do
  @callback run(task_context :: map()) ::
              {:ok, map()} | {:error, String.t()}
end
