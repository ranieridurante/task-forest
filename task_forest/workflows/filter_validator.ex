defmodule TaskForest.Workflows.FilterValidator do
  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "contains",
          "comparison_condition_value_type" => value_type,
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["text", "string"] and value_type in ["text", "string"] do
    String.contains?(value, comparison_value)
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "does_not_contain",
          "comparison_condition_value_type" => value_type,
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["text", "string"] and value_type in ["text", "string"] do
    not String.contains?(value, comparison_value)
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "equals",
          "comparison_condition_value_type" => value_type,
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["text", "string"] and value_type in ["text", "string"] do
    value == comparison_value
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "not_equals",
          "comparison_condition_value_type" => value_type,
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["text", "string"] and value_type in ["text", "string"] do
    value != comparison_value
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "starts_with",
          "comparison_condition_value_type" => value_type,
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["text", "string"] and value_type in ["text", "string"] do
    String.starts_with?(value, comparison_value)
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "ends_with",
          "comparison_condition_value_type" => value_type,
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["text", "string"] and value_type in ["text", "string"] do
    String.ends_with?(value, comparison_value)
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "length_equals",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["text", "string"] do
    String.length(value) == comparison_value
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "length_not_equals",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["text", "string"] do
    String.length(value) != comparison_value
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "is_empty",
          "comparison_condition_value_type" => "null"
        } = _filter,
        value
      )
      when variable_type in ["text", "string"] do
    value == ""
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "is_not_empty",
          "comparison_condition_value_type" => "null"
        } = _filter,
        value
      )
      when variable_type in ["text", "string"] do
    value != ""
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "regular_expression_match",
          "comparison_condition_value_type" => value_type,
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["text", "string"] and value_type in ["text", "string"] do
    Regex.match?(~r/#{comparison_value}/, value)
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "regular_expression_does_not_match",
          "comparison_condition_value_type" => value_type,
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["text", "string"] and value_type in ["text", "string"] do
    not Regex.match?(~r/#{comparison_value}/, value)
  end

  def check_condition(
        %{
          "variable_type" => "number",
          "comparison_condition" => "equals",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    value == comparison_value
  end

  def check_condition(
        %{
          "variable_type" => "number",
          "comparison_condition" => "not_equals",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    value != comparison_value
  end

  def check_condition(
        %{
          "variable_type" => "number",
          "comparison_condition" => "greater_than",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    value > comparison_value
  end

  def check_condition(
        %{
          "variable_type" => "number",
          "comparison_condition" => "less_than",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    value < comparison_value
  end

  def check_condition(
        %{
          "variable_type" => "number",
          "comparison_condition" => "greater_than_or_equal_to",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    value >= comparison_value
  end

  def check_condition(
        %{
          "variable_type" => "number",
          "comparison_condition" => "less_than_or_equal_to",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    value <= comparison_value
  end

  def check_condition(
        %{
          "variable_type" => "number",
          "comparison_condition" => "is_null",
          "comparison_condition_value_type" => "null"
        } = _filter,
        value
      ) do
    is_nil(value)
  end

  def check_condition(
        %{
          "variable_type" => "number",
          "comparison_condition" => "is_not_null",
          "comparison_condition_value_type" => "null"
        } = _filter,
        value
      ) do
    not is_nil(value)
  end

  def check_condition(
        %{
          "variable_type" => "boolean",
          "comparison_condition" => "equals",
          "comparison_condition_value_type" => "boolean",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    value == comparison_value
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "contains_value",
          "comparison_condition_value_type" => value_type,
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["string_array", "text_array"] and value_type in ["string", "text"] do
    Enum.member?(value, comparison_value)
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "does_not_contain_value",
          "comparison_condition_value_type" => value_type,
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["string_array", "text_array"] and value_type in ["string", "text"] do
    not Enum.member?(value, comparison_value)
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "length_equals",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["string_array", "text_array"] do
    length(value) == comparison_value
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "length_not_equals",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["string_array", "text_array"] do
    length(value) != comparison_value
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "regular_expression_match_any",
          "comparison_condition_value_type" => value_type,
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["string_array", "text_array"] and value_type in ["string", "text"] do
    Enum.any?(value, &Regex.match?(~r/#{comparison_value}/, &1))
  end

  def check_condition(
        %{
          "variable_type" => variable_type,
          "comparison_condition" => "regular_expression_does_not_match_any",
          "comparison_condition_value_type" => value_type,
          "comparison_value" => comparison_value
        } = _filter,
        value
      )
      when variable_type in ["string_array", "text_array"] and value_type in ["string", "text"] do
    not Enum.any?(value, &Regex.match?(~r/#{comparison_value}/, &1))
  end

  def check_condition(
        %{
          "variable_type" => "number_array",
          "comparison_condition" => "contains_value",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    Enum.member?(value, comparison_value)
  end

  def check_condition(
        %{
          "variable_type" => "number_array",
          "comparison_condition" => "does_not_contain_value",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    not Enum.member?(value, comparison_value)
  end

  def check_condition(
        %{
          "variable_type" => "number_array",
          "comparison_condition" => "length_equals",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    length(value) == comparison_value
  end

  def check_condition(
        %{
          "variable_type" => "number_array",
          "comparison_condition" => "length_not_equals",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    length(value) != comparison_value
  end

  def check_condition(
        %{
          "variable_type" => "number_array",
          "comparison_condition" => "all_elements_greater_than",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    Enum.all?(value, &(&1 > comparison_value))
  end

  def check_condition(
        %{
          "variable_type" => "number_array",
          "comparison_condition" => "all_elements_less_than",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    Enum.all?(value, &(&1 < comparison_value))
  end

  def check_condition(
        %{
          "variable_type" => "number_array",
          "comparison_condition" => "any_element_greater_than",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    Enum.any?(value, &(&1 > comparison_value))
  end

  def check_condition(
        %{
          "variable_type" => "number_array",
          "comparison_condition" => "any_element_less_than",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    Enum.any?(value, &(&1 < comparison_value))
  end

  def check_condition(
        %{
          "variable_type" => "object_array",
          "comparison_condition" => "length_equals",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    length(value) == comparison_value
  end

  def check_condition(
        %{
          "variable_type" => "object_array",
          "comparison_condition" => "length_not_equals",
          "comparison_condition_value_type" => "number",
          "comparison_value" => comparison_value
        } = _filter,
        value
      ) do
    length(value) != comparison_value
  end
end
