defmodule TaskForest.Repo.Migrations.RemoveAiTokensFromCompany do
  use Ecto.Migration

  def up do
    alter table(:companies) do
      remove :ai_tokens
    end
  end

  def down do
    alter table(:companies) do
      add :ai_tokens, :integer
    end
  end
end
