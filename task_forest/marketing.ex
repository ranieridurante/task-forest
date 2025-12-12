defmodule TaskForest.Marketing do
  import Ecto.Query

  alias TaskForest.Repo
  alias TaskForest.Marketing.ProductUpdate

  def list_recent_product_updates(limit \\ 10) do
    ProductUpdate
    |> order_by([p], desc: p.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end
end
