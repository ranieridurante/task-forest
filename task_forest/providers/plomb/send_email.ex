defmodule TaskForest.Providers.Plomb.SendEmail do
  @behaviour TaskForest.Tasks.ElixirTask

  require Logger

  alias TaskForest.Workflows

  @from "email-task@email-task.plomb.ai"

  def run(%{
        inputs:
          %{
            "plomb_recipient" => to,
            "plomb_subject" => subject,
            "plomb_content" => content,
            "company_users" => company_users
          } =
            inputs,
        task_info: task_info
      }) do
    with :ok <- validate_email(to, company_users),
         subject <- build_subject(subject),
         content <- build_html_body(content, inputs),
         {:ok, _response} <- send_email(to, subject, content, task_info) do
      {:ok, %{"plomb_success" => true}}
    else
      {:error, error_message} ->
        {:error, error_message}
    end
  end

  defp send_email(to, subject, content, task_info) do
    email_data = %{
      "From" => @from,
      "To" => to,
      "Subject" => subject,
      "HtmlBody" => content,
      "MessageStream" => "outbound"
    }

    headers = [
      {"Accept", "application/json"},
      {"Content-Type", "application/json"},
      {"X-Postmark-Server-Token", postmark_config()[:token]}
    ]

    case Tesla.post(postmark_config()[:url], Jason.encode!(email_data), headers: headers) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Tesla.Env{status: status_code, body: body}} ->
        error_message =
          "SendEmail.run - #{task_info.provider} #{task_info.task_template_name} #{task_info.name} - Failed to send email. Status: #{status_code}, Response: #{body}"

        Logger.error(error_message)
        {:error, error_message}

      {:error, reason} ->
        error_message =
          "SendEmail.run - #{task_info.provider} #{task_info.task_template_name} #{task_info.name} - HTTP request failed: #{inspect(reason)}"

        Logger.error(error_message)
        {:error, error_message}
    end
  end

  # TODO: make sure company_users get passed in correctly
  defp validate_email("email-task@email-task.plomb.ai", _company_users) do
    # IO.puts("Validating email #{inspect(company_users)}")
    :ok
  end

  defp validate_email(to, company_users) do
    case Enum.find(company_users, &(&1.email == to)) do
      nil ->
        error_message = "SendEmail.run - Recipient email not found in company users: #{to}"
        Logger.error(error_message)
        {:error, error_message}

      _ ->
        :ok
    end
  end

  defp build_subject(subject) do
    "Plomb Email: #{subject}"
  end

  defp build_html_body(content, inputs) do
    with {:ok, content} <- Workflows.fill_prompt_template(content, inputs) do
      # TODO: clean up this logic
      if String.contains?(content, "<html>") do
        content
      else
        content = render_images_with_textbox(content)

        """
        <html>
          <body>
            <h1>Here are your task results:</h1>
            <div style="white-space: pre-wrap;">#{content}</div>
          </body>
        </html>
        """
      end
    else
      {:error, error} ->
        error_message = "SendEmail.run - Invalid HTML template #{inspect(error)}"
        Logger.error(error_message)
        {:error, error_message}
    end
  end

  defp render_images_with_textbox(text) do
    image_url_regex = ~r/(https?:\/\/.*\.(?:png|jpg|jpeg|gif))/i

    String.replace(text, image_url_regex, fn url ->
      """
      <div>
        <img src="#{url}" alt="Image" />
        <div>Image URL: <input type="text" value="#{url}" readonly style="width: 100%;" /></div>
      </div>
      """
    end)
  end

  defp postmark_config do
    Application.get_env(:task_forest, :postmark)
  end
end
