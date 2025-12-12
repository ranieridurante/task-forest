defmodule TaskForest.Accounts do
  import Ecto.Query

  alias Ecto.Multi

  alias TaskForest.Accounts.Company
  alias TaskForest.Accounts.CompanyProviderApp
  alias TaskForest.Accounts.ProviderKeys
  alias TaskForest.Accounts.User
  alias TaskForest.Accounts.UserCompany
  alias TaskForest.Encryption
  alias TaskForest.Payments
  alias TaskForest.Providers
  alias TaskForest.Providers.Provider
  alias TaskForest.Repo
  alias TaskForest.Utils

  # 60 days
  def session_expiration, do: 60 * 24 * 60 * 60

  def get_user_by_id(user_id) do
    query = from(u in User, where: u.id == ^user_id)
    Repo.one(query)
  end

  def update_company(company_id, params) do
    Multi.new()
    |> Multi.run(:company, fn repo, _changes ->
      company = get_company(company_id, repo)
      store_company(params, company, repo)
    end)
    |> Repo.transaction()
  end

  def update_user_active_company(user_id, company_slug) do
    Multi.new()
    |> Multi.run(:user, fn repo, _changes ->
      user = get_user_by_id(user_id)

      store_user(%{active_company_slug: company_slug}, user, repo)
    end)
    |> Repo.transaction()
  end

  def get_company_by_slug(company_slug, repo \\ Repo) do
    query = from(c in Company, where: c.slug == ^company_slug)
    repo.one(query)
  end

  def get_provider_keys_by_company_id(company_id) do
    query =
      from(p in ProviderKeys, where: fragment("CAST(? AS TEXT)", p.company_id) == ^company_id)

    Repo.all(query)
  end

  def get_providers_with_keys_and_apps(company_id) do
    result =
      Multi.new()
      |> Multi.run(:provider_keys, fn repo, _changes ->
        query =
          from(p in ProviderKeys,
            where: p.company_id == ^company_id,
            select: %{
              provider_id: p.provider_id,
              alias: p.alias,
              id: p.id,
              inserted_at: p.inserted_at
            }
          )

        {:ok, repo.all(query)}
      end)
      |> Multi.run(:provider_apps, fn repo, _changes ->
        query =
          from(app in CompanyProviderApp,
            where: app.company_id == ^company_id,
            select: %{
              provider_slug: app.provider_slug,
              name: app.name,
              inserted_at: app.inserted_at,
              id: app.id
            }
          )

        {:ok, repo.all(query)}
      end)
      |> Multi.run(:providers, fn repo, _changes ->
        empty_map = %{}

        query =
          from(p in Provider,
            where: p.keys != ^empty_map and p.active == true,
            select: p
          )

        {:ok, repo.all(query)}
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{provider_keys: provider_keys, provider_apps: provider_apps, providers: providers}} ->
        providers =
          add_keys_and_apps_to_providers(providers, provider_keys, provider_apps)

        {:ok, providers}

      {:error, error} ->
        {:error, error}
    end
  end

  def add_keys_and_apps_to_providers(providers, stored_keys, apps) do
    indexed_stored_keys = Enum.group_by(stored_keys, & &1.provider_id, & &1)

    indexed_apps = Enum.group_by(apps, & &1.provider_slug, & &1)

    Enum.map(providers, fn provider ->
      keys = indexed_stored_keys[provider.id] || []

      apps = indexed_apps[provider.slug] || []

      provider
      |> Map.merge(%{
        stored_keys: keys,
        apps: apps
      })
    end)
    |> Enum.sort(fn left, right ->
      left_auth_objects = left.stored_keys ++ left.apps
      right_auth_objects = right.stored_keys ++ right.apps

      cond do
        left_auth_objects != [] and right_auth_objects == [] -> true
        left_auth_objects == [] and right_auth_objects != [] -> false
        true -> String.downcase(left.name) <= String.downcase(right.name)
      end
    end)
  end

  def get_providers_with_stored_keys_by_slug(company_id) do
    {:ok, providers} = get_providers_with_keys_and_apps(company_id)

    Enum.reduce(providers, %{}, fn provider, acc ->
      Map.put(acc, provider.slug, provider)
    end)
  end

  def delete_company_provider_app(app_id) do
    case Repo.get(CompanyProviderApp, app_id) do
      nil ->
        {:error, "App not found"}

      app ->
        case Repo.delete(app) do
          {:ok, _struct} ->
            :ok

          {:error, changeset} ->
            {:error, "Failed to delete app: #{inspect(changeset.errors)}"}
        end
    end
  end

  def decrypt_provider_keys(nil), do: {:ok, %{}}

  def decrypt_provider_keys(%{keys: keys}) do
    decrypted_keys = Encryption.decrypt(keys)

    # TODO: Handle the case where the keys are empty
    formatted_keys =
      if decrypted_keys == "" do
        %{}
      else
        decrypted_keys
        |> String.split(",")
        |> Enum.map(fn kv -> String.split(kv, "=") end)
        |> Enum.reduce(%{}, fn
          [k, v], acc -> Map.put(acc, k, v)
          [""], acc -> acc
        end)
      end

    {:ok, formatted_keys}
  rescue
    exception -> {:error, "Error decrypting provider keys: #{inspect(exception.message)}"}
  catch
    error -> {:error, "Error decrypting provider keys: #{inspect(error)}"}
  end

  def encrypt_provider_keys(%{"keys" => keys} = provider_keys) do
    keys =
      keys
      |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
      |> Enum.join(",")

    Map.put(provider_keys, "keys", Encryption.encrypt(keys))
  end

  def decrypt_app_config(nil), do: {:ok, %{}}

  def decrypt_app_config(%{config: config}) do
    decrypted_config = Encryption.decrypt(config)

    # TODO: Handle the case where the config is empty
    formatted_config =
      if decrypted_config == "" do
        %{}
      else
        decrypted_config
        |> String.split(",")
        |> Enum.map(fn kv -> String.split(kv, "=") end)
        |> Enum.reduce(%{}, fn
          [k, v], acc -> Map.put(acc, k, v)
          [""], acc -> acc
        end)
      end

    {:ok, formatted_config}
  rescue
    exception -> {:error, "Error decrypting app config: #{inspect(exception.message)}"}
  catch
    error -> {:error, "Error decrypting app config: #{inspect(error)}"}
  end

  def encrypt_app_config(%{"config" => config} = company_provider_app) do
    config =
      config
      |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
      |> Enum.join(",")

    Map.put(company_provider_app, "config", Encryption.encrypt(config))
  end

  def delete_provider_keys(provider_key_id) do
    Multi.new()
    |> Multi.run(:delete_provider_key, fn repo, _changes ->
      ProviderKeys
      |> repo.get(provider_key_id)
      |> repo.delete()

      {:ok, ""}
    end)
    |> Repo.transaction()
  end

  def get_provider_keys(provider_key_id) do
    query = from(p in ProviderKeys, where: p.id == ^provider_key_id)
    Repo.one(query)
  end

  def get_app(app_id) do
    query = from(app in CompanyProviderApp, where: app.id == ^app_id)
    Repo.one(query)
  end

  def get_app_with_provider(app_id) do
    Multi.new()
    |> Multi.run(:app, fn repo, _changes ->
      app = get_company_provider_app_by_id(app_id, repo)

      {:ok, app}
    end)
    |> Multi.run(:provider, fn repo, %{app: app} ->
      {:ok, Providers.get_provider_by_slug(app.provider_slug, repo)}
    end)
    |> Repo.transaction()
  end

  def delete_provider_keys_returning_connected(company_id, params) do
    Multi.new()
    |> Multi.run(:provider_keys, fn repo, _changes ->
      query =
        from(p in ProviderKeys,
          where: p.provider_id == ^params["provider_id"] and p.company_id == ^company_id
        )

      provider_key = repo.one(query)

      case provider_key do
        nil ->
          {:error, "Provider keys not found"}

        _ ->
          repo.delete(provider_key)
          {:ok, ""}
      end
    end)
    |> Multi.run(:connected_providers, fn repo, %{provider_keys: _provider_keys} ->
      empty_map = %{}

      query =
        from(p in ProviderKeys,
          join: pr in Provider,
          on: pr.id == p.provider_id,
          where: p.company_id == ^company_id and pr.keys != ^empty_map,
          select: pr
        )

      connected_providers = repo.all(query)

      {:ok, connected_providers}
    end)
    |> Repo.transaction()
  end

  def store_provider_keys_returning_connected(company_id, params) do
    Multi.new()
    |> Multi.run(:new_keys, fn repo, _changes ->
      store_provider_keys(params, %ProviderKeys{}, repo)
    end)
    |> Multi.run(:connected_providers, fn repo, %{new_keys: _provider_keys} ->
      empty_map = %{}

      query =
        from(p in ProviderKeys,
          join: pr in Provider,
          on: pr.id == p.provider_id,
          where: p.company_id == ^company_id and pr.keys != ^empty_map,
          select: pr
        )

      connected_providers = repo.all(query)

      {:ok, connected_providers}
    end)
    |> Repo.transaction()
  end

  def store_provider_keys(params) do
    store_provider_keys(params, %ProviderKeys{})
  end

  def store_provider_keys(params, provider_key, repo \\ Repo) do
    params =
      if params["keys"] != nil do
        encrypt_provider_keys(params)
      else
        params
      end

    provider_key
    |> ProviderKeys.changeset(params)
    |> repo.insert()
  end

  def get_company_provider_app_by_id(app_id, repo \\ Repo) do
    query = from(app in CompanyProviderApp, where: app.id == ^app_id)
    repo.one(query)
  end

  def store_company_provider_app(params) do
    store_company_provider_app(params, %CompanyProviderApp{})
  end

  def store_company_provider_app(params, company_provider_app, repo \\ Repo) do
    params = encrypt_app_config(params)

    company_provider_app
    |> CompanyProviderApp.changeset(params)
    |> repo.insert()
  end

  def get_company_provider_keys(company_id, provider_id) do
    query =
      from(p in ProviderKeys,
        where: p.company_id == ^company_id and p.provider_id == ^provider_id,
        select: %{
          id: p.id,
          alias: p.alias,
          inserted_at: p.inserted_at
        }
      )

    Repo.all(query)
  end

  def get_company(company_id, repo \\ Repo) do
    query = from(c in Company, where: c.id == ^company_id)
    repo.one(query)
  end

  def create_session_storing_user(user_info) do
    Multi.new()
    |> Multi.run(:registered_user, fn repo, _changes ->
      {:ok, repo.get_by(User, email: user_info.email)}
    end)
    |> Multi.run(:stored_user, fn repo, %{registered_user: user} ->
      params = %{
        email: user_info.email,
        first_name: user_info.first_name || "",
        last_name: user_info.last_name || ""
      }

      user = user || %User{}

      store_user(params, user, repo)
    end)
    |> Multi.run(:companies_before_session, fn repo, %{stored_user: user} ->
      {:ok, get_user_companies(user.id, repo)}
    end)
    |> Multi.run(:active_company, fn repo, %{companies_before_session: companies, stored_user: user} ->
      if companies == [] do
        slug = :crypto.strong_rand_bytes(5) |> Base.encode16() |> String.downcase()

        company = %{
          name: "#{user.first_name}'s Personal Projects",
          slug: slug
        }

        {:ok, company} = store_company(company, %Company{}, repo)

        user_company = %{
          user_id: user.id,
          company_id: company.id,
          is_admin: true
        }

        store_user_company(user_company, %UserCompany{}, repo)

        company_with_permissions = %{
          id: company.id,
          name: company.name,
          slug: company.slug,
          website: company.website,
          is_admin: true,
          roles: []
        }

        {:ok, company_with_permissions}
      else
        {:ok, hd(companies)}
      end
    end)
    |> Multi.run(:updated_user, fn repo,
                                   %{
                                     active_company: active_company,
                                     stored_user: user
                                   } ->
      if user.active_company_slug != active_company.slug do
        user
        |> User.changeset(%{active_company_slug: active_company.slug})
        |> repo.update()
      else
        {:ok, user}
      end
    end)
    |> Repo.transaction()
  end

  def store_user(user_params, user, repo \\ Repo) do
    user
    |> User.changeset(user_params)
    |> repo.insert_or_update()
  end

  def store_company(company_params, company, repo \\ Repo) do
    company
    |> Company.changeset(company_params)
    |> repo.insert_or_update()
  end

  def store_user_company(user_company_params, user_company, repo \\ Repo) do
    user_company
    |> UserCompany.changeset(user_company_params)
    |> repo.insert_or_update()
  end

  def user_has_permission(nil, _allowed_roles), do: false
  def user_has_permission(%{is_admin: true} = _user_active_company, _allowed_roles), do: true

  def user_has_permission(%{roles: roles} = _user_active_company, allowed_roles) do
    Enum.any?(roles, &(&1 in allowed_roles))
  end

  def store_temporary_oauth2_code(code, provider_id, company_id) do
    encrypted_code = Utils.encrypt(code)
    hashed_code = Utils.simple_hash(code)

    store_provider_keys(%{
      "temporary_code" => encrypted_code,
      "temporary_code_hash" => hashed_code,
      "provider_id" => provider_id,
      "company_id" => company_id,
      "alias" => "Temporary Code"
    })
  end

  def store_oauth2_access_token(app_id, token) do
    app = get_company_provider_app_by_id(app_id)

    provider = Providers.get_provider_by_slug(app.provider_slug)

    store_provider_keys(%{
      "keys" => %{
        "access_token" => token
      },
      "provider_id" => provider.id,
      "company_id" => app.company_id,
      "alias" => "#{provider.name} Account"
    })
  end

  def delete_temporary_oauth2_tokens(app_id) do
    app = get_company_provider_app_by_id(app_id)

    provider = Providers.get_provider_by_slug(app.provider_slug)

    query =
      from(p in ProviderKeys,
        where:
          p.provider_id == ^provider.id and p.company_id == ^app.company_id and
            not is_nil(p.temporary_code_hash)
      )

    Repo.delete_all(query)

    :ok
  end

  def add_new_account_credits(company_id) do
    Elixir.Task.start(fn ->
      Payments.add_credits(:credits, company_id, 25, "PROMOTION", "Welcome to Plomb!")
    end)
  end

  def get_user_companies(user_id, repo \\ Repo) do
    query =
      from(u in User,
        where: u.id == ^user_id,
        join: uc in UserCompany,
        on: uc.user_id == u.id,
        join: c in Company,
        on: c.id == uc.company_id,
        select: %{
          id: c.id,
          name: c.name,
          slug: c.slug,
          website: c.website,
          is_admin: uc.is_admin,
          roles: uc.roles
        }
      )

    repo.all(query)
  end

  def generate_auth_token() do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16()
    |> String.downcase()
  end

  def store_auth_token(token, company_slug, repo \\ Repo) do
    encrypted_token = Encryption.encrypt(token)

    company = get_company_by_slug(company_slug, repo)

    store_company(%{auth_token: encrypted_token}, company, repo)

    token
  end

  def validate_auth_token(token, company_slug) do
    case retrieve_company_auth_token(company_slug) do
      nil -> false
      stored_token -> stored_token == token
    end
  end

  def retrieve_company_auth_token(company_slug) do
    query =
      from(company in Company,
        where: company.slug == ^company_slug,
        select: %{
          auth_token: company.auth_token
        }
      )

    with %{auth_token: auth_token} <- Repo.one(query),
         false <- is_nil(auth_token),
         decrypted_auth_token <- Encryption.decrypt(auth_token) do
      decrypted_auth_token
    else
      _ -> nil
    end
  end
end
