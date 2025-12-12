defmodule TaskForest.Workflows.WorkflowConfig do
  @derive Jason.Encoder
  defstruct model_provider: nil, model_id: nil, model_params: nil, max_retries: nil

  @type t :: %__MODULE__{
          model_provider: String.t(),
          model_id: String.t(),
          model_params: map(),
          max_retries: non_neg_integer()
        }
end
