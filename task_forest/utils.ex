defmodule TaskForest.Utils do
  defdelegate encrypt(text), to: TaskForest.Encryption
  defdelegate decrypt(encrypted_text), to: TaskForest.Encryption

  def string_map_to_keyword_list(map) do
    map
    |> Map.to_list()
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
  end

  def validate_cron_expression(cron_expression) do
    case parse_cron_expression(cron_expression) do
      {:ok, _parsed_expression} -> {:ok, "Valid cron expression"}
      {:error, _reason} -> {:error, "Invalid cron expression"}
    end
  end

  def parse_cron_expression(cron_expression) do
    Oban.Cron.Expression.parse(cron_expression)
  end

  def simple_hash(string) do
    :crypto.hash(:md5, string)
    |> Base.encode16()
    |> String.downcase()
  end

  def atom_map_to_string_map(map) do
    map
    |> Map.to_list()
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
    |> Map.new()
  end

  def string_map_to_atom_map(map) do
    map
    |> Map.to_list()
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Map.new()
  end

  def is_uuid?(str) do
    Regex.match?(
      ~r/\A[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-4[a-fA-F0-9]{3}-[89aAbB][a-fA-F0-9]{3}-[a-fA-F0-9]{12}\z/,
      str
    )
  end

  def singularize(word) do
    case String.ends_with?(word, "s") do
      true -> String.slice(word, 0..-2//1)
      false -> word
    end
  end

  def parse_json_strings(data, keys) do
    Enum.reduce(data, %{}, fn {key, value}, acc ->
      if Enum.member?(keys, key) and is_stringified_json?(value) do
        Map.put(acc, key, Jason.decode!(value))
      else
        Map.put(acc, key, value)
      end
    end)
  end

  defp is_stringified_json?(value) do
    case value do
      nil -> false
      "" -> false
      _ -> is_binary(value) and String.starts_with?(value, "{") and String.ends_with?(value, "}")
    end
  end

  def force_snake_case_keys(nil), do: %{}

  def force_snake_case_keys(map) when is_map(map) do
    map
    |> Map.to_list()
    |> Enum.map(fn {k, v} ->
      k =
        k
        |> String.downcase()
        |> String.replace(" ", "_")

      {k, v}
    end)
    |> Map.new()
  end

  def sanitize_malformed_json_string(json_string) do
    json_string
    |> String.replace("\"\"", "\"")
    |> String.replace("\\n", "\n")
    |> String.replace("\\\"", "\"")
    |> String.trim()
  end

  def maybe_extract_json_from_markdown(json_string) do
    case Regex.run(~r/```json\s*(.*)\s*```/s, json_string) do
      [_, extracted_json] ->
        extracted_json
        |> String.replace("\\n", "\n")
        |> String.replace("\\\"", "\"")
        |> String.trim()

      nil ->
        json_string
    end
  end

  def maybe_extract_json_from_reasoning(text) do
    case Regex.run(~r/\{[\s\S]*"plomb_ai_response":\s*"([^"]*)"[\s\S]*\}/s, text) do
      [_, extracted_json] ->
        Jason.encode!(%{
          "plomb_ai_response" =>
            extracted_json
            |> String.replace("\\n", "\n")
            |> String.replace("\\\"", "\"")
            |> String.trim()
        })

      nil ->
        text
    end
  end

  def update_map_keys_by_key(list, key, target_value, updates) do
    update_map_keys_by_key(list, key, target_value, updates, false)
  end

  defp update_map_keys_by_key([], _key, _target_value, _updates, _updated), do: []

  defp update_map_keys_by_key([map | tail], key, target_value, updates, false) do
    if Map.get(map, key) == target_value do
      [Map.merge(map, updates) | tail]
    else
      [map | update_map_keys_by_key(tail, key, target_value, updates, false)]
    end
  end

  defp update_map_keys_by_key([head | tail], key, target_value, updates, updated) do
    [head | update_map_keys_by_key(tail, key, target_value, updates, updated)]
  end

  def generate_unique_slug(original_string) do
    original_string
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> Kernel.<>(
      ("-" <> :crypto.strong_rand_bytes(4))
      |> Base.encode16()
      |> String.downcase()
    )
  end

  def add_number_commas(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> add_number_commas()
  end

  def add_number_commas(number) do
    Regex.replace(~r/(?<=\d)(?=(\d{3})+$)/, number, ",")
  end
end
