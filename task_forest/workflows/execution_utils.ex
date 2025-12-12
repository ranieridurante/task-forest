defmodule TaskForest.Workflows.ExecutionUtils do
  def parse_outputs(outputs, outputs_definition, inputs_definition) do
    output_keys = Map.keys(outputs_definition)
    input_keys = Map.keys(inputs_definition)
    extra_keys = ["execution_id", "inputs_hash", "workflow_id"]

    final_outputs = filter_outputs(outputs, output_keys)

    intermediate_outputs =
      outputs
      |> Map.drop(output_keys)
      |> Map.drop(input_keys)
      |> Map.drop(extra_keys)

    {final_outputs, intermediate_outputs}
  end

  defp filter_outputs(outputs, output_keys) do
    Enum.reduce(output_keys, %{}, fn output_key, acc ->
      outputs
      |> Enum.filter(fn {k, _} -> String.contains?(k, output_key) end)
      |> Map.new()
      |> then(fn filtered_outputs ->
        Map.merge(acc, filtered_outputs)
      end)
    end)
  end
end
