defmodule TaskForest.Providers.Plomb.ExtractHtmlText do
  @behaviour TaskForest.Tasks.ElixirTask

  require Logger

  @impl true
  def run(%{inputs: %{"plomb_raw_html" => raw_html}, task_info: task_info}) do
    error_prefix =
      "ExtractHtmlText.run - #{task_info.provider} #{task_info.task_template_name} #{task_info.name}"

    with raw_html <- String.replace(raw_html, "&quot;", "'"),
         {:ok, html_tree} <- Floki.parse_document(raw_html),
         html_tree <- Floki.filter_out(html_tree, "style"),
         html_tree <- Floki.filter_out(html_tree, "script"),
         html_tree <- Floki.filter_out(html_tree, "nav"),
         html_tree <- Floki.filter_out(html_tree, "aside"),
         html_tree <- Floki.filter_out(html_tree, "footer"),
         html_tree <- Floki.filter_out(html_tree, "head"),
         text <- Floki.text(html_tree, sep: " ") do
      {:ok, %{"plomb_html_text" => text}}
    else
      {:error, reason} ->
        Logger.error("#{error_prefix} - Failed to extract HTML text: #{inspect(reason)}")
        {:error, "#{error_prefix} - Failed to extract HTML text: #{inspect(reason)}"}

      error ->
        Logger.error("#{error_prefix} - Failed to extract HTML text: #{inspect(error)}")
        {:error, "#{error_prefix} - Failed to extract HTML text: #{inspect(error)}"}
    end
  end
end
