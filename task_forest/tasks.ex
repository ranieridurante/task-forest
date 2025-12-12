defmodule TaskForest.Tasks do
  import Ecto.Query

  alias Ecto.Multi
  alias TaskForest.Providers.Provider
  alias TaskForest.Repo
  alias TaskForest.Tasks.Task
  alias TaskForest.Tasks.TaskTemplate

  def get_task_providers_with_styles(task_ids) do
    result =
      Multi.new()
      |> Multi.run(:data, fn repo, _ ->
        query =
          from(t in Task)
          |> where([t], t.id in ^task_ids)
          |> join(:left, [t], tt in TaskTemplate, on: t.task_template_id == tt.id)
          |> select([t, tt], %{
            t.id => tt.provider_slug,
            "task_template_name" => tt.name,
            "style" => %{
              tt.provider_slug => tt.style
            }
          })

        {:ok, repo.all(query)}
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{data: data}} ->
        {tasks_with_providers, provider_styles} =
          Enum.map_reduce(data, %{}, fn task_data, provider_styles ->
            task_id_with_provider =
              if task_data["task_template_name"] == "PlombAI" do
                [task_id] =
                  task_data
                  |> Map.drop(["style", "task_template_name"])
                  |> Map.keys()

                %{task_id => "plombai"}
              else
                Map.drop(task_data, ["style", "task_template_name"])
              end

            provider_styles =
              if task_data["task_template_name"] == "PlombAI" do
                Map.merge(provider_styles, %{"plombai" => task_data["style"]["plomb"]})
              else
                Map.merge(provider_styles, task_data["style"])
              end

            {task_id_with_provider, provider_styles}
          end)

        tasks_with_providers =
          Enum.reduce(tasks_with_providers, %{}, fn map, acc ->
            Map.merge(acc, map)
          end)

        %{tasks_with_providers: tasks_with_providers, provider_styles: provider_styles}

      {:error, error_msg} ->
        %{error: error_msg}
    end
  end

  def get_task_templates_by_provider(provider_slug) do
    query =
      from(t in TaskTemplate,
        where: t.provider_slug == ^provider_slug and t.access_type == "public"
      )

    Repo.all(query)
  end

  def get_featured_task_templates_by_provider(provider_slug) do
    query =
      from(t in TaskTemplate,
        where: t.provider_slug == ^provider_slug and t.featured == true and t.access_type == "public"
      )

    Repo.all(query)
  end

  @doc """
  Return ALL task templates in the DB.
  Used in the backoffice. Do not use for user-facing pages.
  """
  def get_task_templates(opts \\ []) do
    page = opts[:page] || 1
    page_size = opts[:page_size] || 200

    provider = opts[:provider]

    offset = (page - 1) * page_size

    result =
      Multi.new()
      |> Multi.run(:task_templates, fn repo, _ ->
        query =
          from(t in TaskTemplate)
          |> limit([_t], ^page_size)
          |> offset([_t], ^offset)
          |> select(
            [t],
            %{
              id: t.id,
              name: t.name,
              description: t.description,
              provider_slug: t.provider_slug,
              featured: t.featured,
              access_type: t.access_type,
              inserted_at: t.inserted_at,
              updated_at: t.updated_at
            }
          )

        query =
          if provider do
            query
            |> where([t], t.provider_slug == ^provider)
          else
            query
          end

        {:ok, repo.all(query)}
      end)
      |> Multi.run(:task_templates_count, fn repo, _ ->
        query = from(t in TaskTemplate, select: count(t.id))

        query =
          if provider do
            query
            |> where([t], t.provider_slug == ^provider)
          else
            query
          end

        {:ok, repo.one(query)}
      end)
      |> Multi.run(:providers, fn repo, _ ->
        query =
          from(p in Provider,
            select: %{
              p.slug => p
            }
          )

        {:ok, repo.all(query)}
      end)
      |> Repo.transaction()

    case result do
      {:ok,
       %{
         task_templates: task_templates,
         task_templates_count: task_templates_count,
         providers: providers
       }} ->
        providers_map = Enum.reduce(providers, %{}, fn tt, acc -> Map.merge(acc, tt) end)

        data =
          task_templates
          |> Enum.map(fn task_template ->
            provider = providers_map[task_template.provider_slug]

            task_template
            |> then(fn data ->
              struct(TaskTemplate, data)
            end)
            |> Map.put(:provider, provider)
          end)
          |> Enum.sort_by(&{&1.provider, &1.featured, &1.access_type}, :desc)

        provider_slugs = Map.keys(providers_map)

        %{data: data, count: task_templates_count, providers: provider_slugs}

      {:error, _} ->
        []
    end
  end

  def get_task_template(id, repo \\ Repo) do
    result =
      Multi.new()
      |> Multi.run(:task_template, fn repo, _ ->
        query = from(t in TaskTemplate, where: t.id == ^id)
        {:ok, repo.one(query)}
      end)
      |> Multi.run(:provider, fn repo, %{task_template: task_template} ->
        query = from(p in Provider, where: p.slug == ^task_template.provider_slug)
        {:ok, repo.one(query)}
      end)
      |> repo.transaction()

    case result do
      {:ok, %{task_template: task_template, provider: provider}} ->
        task_template
        |> Map.put(:provider, provider)

      {:error, _} ->
        nil
    end
  end

  def delete_task_template(task_template) do
    Repo.delete(task_template)
  end

  def update_task_template_changeset(task_template, params \\ %{}) do
    TaskTemplate.changeset(task_template, params)
  end

  def store_task_template(task_template, params) do
    changeset = TaskTemplate.changeset(task_template, params)

    result =
      Multi.new()
      |> Multi.insert_or_update(:stored_task_template, changeset)
      |> Multi.run(:task_template, fn repo, %{stored_task_template: task_template} ->
        {:ok, get_task_template(task_template.id, repo)}
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{task_template: task_template}} ->
        {:ok, task_template}

      {:error, _} ->
        {:error, changeset}
    end
  end

  def get_user_task_templates(user_id) do
    {:ok, %{providers: providers, task_templates: task_templates}} =
      Multi.new()
      |> Multi.run(:providers, fn repo, _ ->
        {:ok, repo.all(Provider)}
      end)
      |> Multi.run(:task_templates, fn repo, _ ->
        query =
          from(t in TaskTemplate)
          |> where(
            [t],
            t.creator_id == ^user_id or t.access_type == "public"
          )

        {:ok, repo.all(query)}
      end)
      |> Repo.transaction()

    task_templates
    |> Enum.map(fn task_template ->
      provider =
        Enum.find(providers, fn provider ->
          provider.slug == task_template.provider_slug
        end)

      data =
        task_template
        |> Map.delete(:__struct__)
        |> Map.delete(:__meta__)
        |> Map.merge(%{
          provider_logo: provider.logo,
          provider_website: provider.website,
          provider_name: provider.name
        })

      {task_template.id, data}
    end)
    |> Enum.sort_by(&elem(&1, 1).provider_name)
    |> Enum.into(%{})
  end
end
