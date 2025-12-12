defmodule TaskForest.Models.ModelProvider do
  @callback call(
              model_id :: String.t(),
              model_params :: list(),
              input_params :: map(),
              provider_keys :: map(),
              task_info :: map()
            ) ::
              {:ok, map()} | {:error, String.t()}
end
