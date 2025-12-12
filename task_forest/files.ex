defmodule TaskForest.Files do
  alias TaskForest.Files.MediaAsset
  alias TaskForest.Repo

  # 24 hours
  @media_asset_url_expiration 24 * 3600

  def store_media_asset(params) do
    store_media_asset(params, %MediaAsset{})
  end

  def store_media_asset(params, media_asset) do
    media_asset
    |> MediaAsset.changeset(params)
    |> Repo.insert_or_update()
  end

  def get_media_asset_by_id(media_asset_id) do
    Repo.get(MediaAsset, media_asset_id)
  end

  def get_media_asset_url(media_asset_id) do
    media_asset = get_media_asset_by_id(media_asset_id)

    gcs_config = Application.get_env(:task_forest, :google_cloud_services)

    client = GcsSignedUrl.Client.load(gcs_config[:plomb_media_service_credentials])

    GcsSignedUrl.generate_v4(client, gcs_config[:media_bucket], media_asset.storage_key,
      expires: @media_asset_url_expiration
    )
  end
end
