defmodule TaskForest.Files.MediaUpload do
  alias TaskForest.Files

  def store_file_from_binary(
        binary_data,
        %{filename: filename, content_type: content_type, byte_size: byte_size} = _file_metadata,
        company_id,
        workflow_id,
        execution_id,
        created_by_id,
        created_by_type
      ) do
    storage_key = generate_storage_key(company_id, workflow_id, execution_id, filename)

    tmp_path = generate_tmp_path(storage_key)

    try do
      :ok = write_to_file(binary_data, tmp_path)

      media_asset_data = %{
        company_id: company_id,
        workflow_id: workflow_id,
        execution_id: execution_id,
        original_filename: filename,
        content_type: content_type,
        byte_size: byte_size,
        storage_key: storage_key,
        created_by_id: created_by_id,
        created_by_type: created_by_type
      }

      upload_and_store_metadata(tmp_path, media_asset_data)
    after
      File.rm(tmp_path)
    end
  end

  def store_file_from_http(url, company_id, workflow_id, execution_id, created_by_id, created_by_type) do
    original_filename = Path.basename(url)

    # TODO: get content-type from download request

    storage_key = generate_storage_key(company_id, workflow_id, execution_id, original_filename)

    tmp_path = generate_tmp_path(storage_key)

    try do
      :ok = download_to_file(url, tmp_path)

      media_asset_data = %{
        company_id: company_id,
        workflow_id: workflow_id,
        execution_id: execution_id,
        original_filename: original_filename,
        storage_key: storage_key,
        created_by_id: created_by_id,
        created_by_type: created_by_type
      }

      upload_and_store_metadata(tmp_path, media_asset_data)
    after
      File.rm(tmp_path)
    end
  end

  defp generate_storage_key(company_id, workflow_id, execution_id, filename) do
    ts = DateTime.utc_now() |> DateTime.to_iso8601(:basic)

    "#{company_id}/#{workflow_id}/#{execution_id}/#{ts}-#{filename}"
  end

  def generate_tmp_path(storage_key) do
    "/tmp/#{String.replace(storage_key, "/", "-")}"
  end

  defp upload_and_store_metadata(tmp_path, media_asset_data) do
    {:ok, content_type, byte_size} = upload_file(tmp_path, media_asset_data)

    data =
      Map.merge(media_asset_data, %{
        content_type: content_type,
        byte_size: byte_size
      })

    Files.store_media_asset(data)
  end

  def write_to_file(binary_data, dest_path) do
    File.open!(dest_path, [:write], fn file ->
      IO.binwrite(file, binary_data)
    end)
  end

  defp download_to_file(url, dest_path) do
    File.open!(dest_path, [:write], fn file ->
      Tesla.get!(url, opts: [adapter: [stream_to: self(), async: :once]])

      receive do
        {:http, :body, data} ->
          IO.binwrite(file, data)
      after
        10_000 -> :timeout
      end
    end)
  end

  def upload_file(
        path,
        %{content_type: content_type, byte_size: byte_size, storage_key: storage_key} = _media_asset_data
      ) do
    {:ok, %{token: access_token}} =
      Goth.fetch(TaskForestGoth, %{scope: "https://www.googleapis.com/auth/devstorage.full_control"})

    conn =
      Tesla.client(
        [
          {Tesla.Middleware.Headers, [{"authorization", "Bearer #{access_token}"}]}
        ],
        {Tesla.Adapter.Hackney, [recv_timeout: 60_000]}
      )

    object = %GoogleApi.Storage.V1.Model.Object{name: storage_key, contentType: content_type}

    gcs_config = Application.get_env(:task_forest, :google_cloud_services)

    {:ok, _response} =
      GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_simple(
        conn,
        gcs_config[:media_bucket],
        "multipart",
        object,
        path,
        [fields: "id"],
        []
      )

    {:ok, content_type, byte_size}
  end
end
