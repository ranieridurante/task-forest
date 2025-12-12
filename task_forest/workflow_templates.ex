defmodule TaskForest.WorkflowTemplates do
  import Ecto.Query

  require Logger

  alias Ecto.Multi
  alias TaskForest.Repo
  alias TaskForest.Tasks.Task
  alias TaskForest.Tasks.TaskTemplate
  alias TaskForest.Utils
  alias TaskForest.Workflows
  alias TaskForest.Workflows.GraphUtils
  alias TaskForest.Workflows.Workflow
  alias TaskForest.WorkflowTemplates.Category
  alias TaskForest.WorkflowTemplates.WorkflowTemplate
  alias TaskForest.WorkflowTemplates.WorkflowTemplateCategory
  alias TaskForest.WorkflowTemplates.WorkflowTemplateCollection
  alias TaskForest.WorkflowTemplates.WorkflowTemplateCollectionFeaturedProvider
  alias TaskForest.WorkflowTemplates.WorkflowTemplateCollectionWorkflowTemplate

  @type filters :: %{
          search_term: String.t(),
          selected_category_ids: [String.t()]
        }

  def get_all_collections(opts \\ []) do
    page_size = opts[:page_size] || 10
    page = opts[:page] || 1

    offset = (page - 1) * page_size

    query =
      from(wtc in WorkflowTemplateCollection,
        limit: ^page_size,
        offset: ^offset,
        order_by: [desc: wtc.inserted_at]
      )

    Repo.all(query)
  end

  def get_all_categories do
    query = from(c in Category, select: c)
    Repo.all(query)
  end

  def get_category_by_slug(slug) do
    Repo.get_by(Category, slug: slug)
  end

  def get_workflow_template_categories(workflow_template_id) do
    results =
      Multi.new()
      |> Multi.run(:workflow_template_categories, fn repo, _ ->
        query =
          from(wtc in WorkflowTemplateCategory,
            where: wtc.workflow_template_id == ^workflow_template_id
          )

        {:ok, repo.all(query)}
      end)
      |> Multi.run(:categories, fn repo, %{workflow_template_categories: workflow_template_categories} ->
        category_ids = Enum.map(workflow_template_categories, & &1.category_id)

        query =
          from(c in Category,
            where: c.id in ^category_ids
          )

        {:ok, repo.all(query)}
      end)
      |> Repo.transaction()

    case results do
      {:ok, %{categories: categories}} ->
        categories

      {:error, _} ->
        # TODO: handle errors properly
        []
    end
  end

  def get_workflow_template(workflow_template_id, repo \\ Repo) do
    query = from(wt in WorkflowTemplate, where: wt.id == ^workflow_template_id)
    repo.one(query)
  end

  def update_workflow_template_changeset(workflow_template, params \\ %{}) do
    WorkflowTemplate.changeset(workflow_template, params)
  end

  def store_workflow_template(workflow_template, params) do
    changeset = WorkflowTemplate.changeset(workflow_template, params)

    result =
      Multi.new()
      |> Multi.insert_or_update(:stored_workflow_template, changeset)
      |> Multi.run(:workflow_template, fn repo, %{stored_workflow_template: workflow_template} ->
        {:ok, get_workflow_template(workflow_template.id, repo)}
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{workflow_template: workflow_template}} ->
        {:ok, workflow_template}

      {:error, _} ->
        {:error, changeset}
    end
  end

  def delete_workflow_template(nil) do
    {:error, "Workflow template not found"}
  end

  def delete_workflow_template(workflow_template) do
    result =
      Multi.new()
      |> Multi.run(:delete_reference_tasks, fn repo, _ ->
        query =
          from(t in Task,
            where: t.workflow_id == ^workflow_template.workflow_id and t.is_template_reference == true
          )

        {:ok, repo.delete_all(query)}
      end)
      |> Multi.run(:delete_reference_workflow, fn repo, _ ->
        reference_workflow = Workflows.get_reference_workflow(workflow_template.workflow_id, repo)

        repo.delete(reference_workflow)
      end)
      |> Multi.run(:delete_workflow_template, fn repo, _ ->
        repo.delete(workflow_template)
      end)
      |> Repo.transaction()

    case result do
      {:ok, _} ->
        :ok

      {:error, error_message} ->
        Logger.error("An error occurred while deleting the workflow template: #{inspect(error_message)}")

        {:error, "An error ocurred while deleting the workflow template."}
    end
  end

  def get_workflow_template_collection(collection_id) do
    query = from(wtc in WorkflowTemplateCollection, where: wtc.id == ^collection_id)
    Repo.one(query)
  end

  # Used for the backoffice. Avoid for user-facing pages.
  def get_all_workflow_templates(filters \\ %{}, opts \\ []) do
    page_size = opts[:page_size] || 10
    page = opts[:page] || 1

    offset = (page - 1) * page_size

    base_query =
      from(wt in WorkflowTemplate,
        limit: ^page_size,
        offset: ^offset,
        order_by: [desc: wt.featured, desc: wt.updated_at],
        preload: [:categories]
      )

    base_query
    |> maybe_add_text_search_filter(filters[:search_term])
    |> maybe_add_category_filter(filters[:selected_category_ids])
    |> Repo.all()
  end

  def filter_workflow_templates(filters \\ %{}, opts \\ []) do
    page_size = opts[:page_size] || 10
    page = opts[:page] || 1

    offset = (page - 1) * page_size

    base_query =
      from(wt in WorkflowTemplate,
        where: wt.published == true,
        limit: ^page_size,
        offset: ^offset,
        order_by: [desc: wt.featured, desc: wt.updated_at],
        preload: [:categories]
      )

    base_query
    |> maybe_add_collection_filter(filters[:collection])
    |> maybe_add_text_search_filter(filters[:search_term])
    |> maybe_add_category_filter(filters[:selected_category_ids])
    |> maybe_add_provider_filter(filters[:provider])
    |> Repo.all()
  end

  def get_collection_by_slug(slug) do
    Repo.get_by(WorkflowTemplateCollection, slug: slug)
  end

  def create_workflow_template(%{"workflow_id" => workflow_id} = workflow_template_params) do
    result =
      Multi.new()
      |> Multi.run(:tasks, fn repo, _changes ->
        query =
          from t in Task,
            where: t.workflow_id == ^workflow_id and t.is_template_reference == false

        {:ok, repo.all(query)}
      end)
      |> Multi.run(:duplicated_tasks, fn repo, %{tasks: tasks} ->
        duplicated_tasks =
          Enum.map(tasks, fn task ->
            now = NaiveDateTime.utc_now(:second)

            task
            |> Map.drop([:id, :__struct__, :__meta__])
            |> Map.put(:is_template_reference, true)
            |> Map.put(:template_reference_for_id, task.id)
            |> Map.put(:id, Ecto.UUID.generate())
            |> Map.put(:inserted_at, now)
            |> Map.put(:updated_at, now)
          end)

        case repo.insert_all(Task, duplicated_tasks, returning: true) do
          {count, _} when count > 0 -> {:ok, duplicated_tasks}
          _ -> {:error, "Failed to duplicate tasks"}
        end
      end)
      |> Multi.run(:workflow, fn repo, _ ->
        {:ok, repo.get(Workflow, workflow_id)}
      end)
      |> Multi.run(:reference_workflow, fn repo,
                                           %{
                                             workflow: workflow,
                                             duplicated_tasks: duplicated_tasks
                                           } ->
        updated_graph = GraphUtils.remap_graph_tasks(workflow.graph, duplicated_tasks)

        data =
          workflow
          |> Map.drop([:id, :__struct__, :__meta__, :inserted_at, :updated_at])
          |> Map.put(:graph, updated_graph)
          |> Map.put(:template_reference_for_id, workflow_id)

        Workflows.store_workflow(data, %Workflow{}, repo)
      end)
      |> Multi.run(:task_templates, fn repo, %{duplicated_tasks: duplicated_tasks} ->
        task_template_ids =
          Enum.map(duplicated_tasks, fn task -> task.task_template_id end)

        task_templates = repo.all(from tt in TaskTemplate, where: tt.id in ^task_template_ids)

        {:ok, task_templates}
      end)
      |> Multi.run(:workflow_template, fn repo, %{task_templates: task_templates} ->
        provider_slugs =
          task_templates
          |> Enum.map(& &1.provider_slug)
          |> Enum.uniq()
          |> Enum.join(",")

        slug = Utils.generate_unique_slug(workflow_template_params["name"])

        workflow_template_params =
          Map.merge(workflow_template_params, %{
            "provider_slugs" => provider_slugs,
            "slug" => slug,
            "tasks_updated_at" => NaiveDateTime.utc_now(:second)
          })

        %WorkflowTemplate{}
        |> WorkflowTemplate.changeset(workflow_template_params)
        |> repo.insert()
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{workflow_template: workflow_template}} ->
        {:ok, workflow_template}

      {:error, error_message} ->
        Logger.error("Failed to create workflow template: #{inspect(error_message)}")

        {:error, "Failed to create workflow template."}
    end
  end

  def create_workflow(company_id, workflow_template_id) do
    result =
      Multi.new()
      |> Multi.run(:workflow_template, fn repo, _ ->
        {:ok, get_workflow_template(workflow_template_id, repo)}
      end)
      |> Multi.run(:reference_workflow, fn repo, %{workflow_template: workflow_template} ->
        {:ok, Workflows.get_reference_workflow(workflow_template.workflow_id, repo)}
      end)
      |> Multi.run(:reference_tasks, fn repo, %{workflow_template: workflow_template} ->
        query =
          from(t in Task,
            where: t.workflow_id == ^workflow_template.workflow_id and t.is_template_reference == true
          )

        {:ok, repo.all(query)}
      end)
      |> Multi.run(:workflow, fn repo,
                                 %{
                                   workflow_template: workflow_template,
                                   reference_workflow: reference_workflow
                                 } ->
        data =
          reference_workflow
          |> Map.drop([
            :id,
            :__struct__,
            :__meta__,
            :inserted_at,
            :updated_at,
            :template_reference_for_id
          ])
          |> Map.merge(%{
            name: workflow_template.name,
            description: workflow_template.short_description,
            company_id: company_id
          })

        Workflows.store_workflow(data, %Workflow{}, repo)
      end)
      |> Multi.run(:tasks, fn repo, %{workflow: workflow, reference_tasks: reference_tasks} ->
        tasks =
          Enum.map(reference_tasks, fn reference_task ->
            now = NaiveDateTime.utc_now(:second)

            reference_task
            |> Map.drop([:id, :__struct__, :__meta__])
            |> Map.merge(%{
              id: Ecto.UUID.generate(),
              workflow_id: workflow.id,
              is_template_reference: false,
              template_reference_for_id: reference_task.id,
              inserted_at: now,
              updated_at: now
            })
          end)

        case repo.insert_all(Task, tasks, returning: true) do
          {count, _} when count > 0 -> {:ok, tasks}
          _ -> {:error, "Failed to duplicate tasks"}
        end
      end)
      |> Multi.run(:updated_workflow, fn repo, %{workflow: workflow, tasks: tasks} ->
        updated_graph = GraphUtils.remap_graph_tasks(workflow.graph, tasks)

        Workflows.store_workflow(%{graph: updated_graph}, workflow, repo)
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{workflow_template: workflow_template, workflow: workflow}} ->
        Elixir.Task.start(fn -> increase_workflow_template_usage_count(workflow_template.id) end)

        {:ok, workflow}

      {:error, error_msg} ->
        Logger.error("Error occurred: #{inspect(error_msg)}")

        {:error, "There was an error creating the workflow."}
    end
  end

  def increase_workflow_template_usage_count(workflow_template_id) do
    Multi.new()
    |> Multi.run(:set_tx_isolation_level, fn repo, _ ->
      repo.query!("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;")
      {:ok, nil}
    end)
    |> Multi.run(:workflow_template, fn repo, _ ->
      {:ok, get_workflow_template(workflow_template_id, repo)}
    end)
    |> Multi.run(:updated_workflow_template, fn repo, %{workflow_template: workflow_template} ->
      workflow_template
      |> WorkflowTemplate.changeset(%{usage_count: workflow_template.usage_count + 1})
      |> repo.update()
    end)
    |> Repo.transaction()
  end

  def get_workflow_template_by_slug(slug) do
    query = from(wt in WorkflowTemplate, where: wt.slug == ^slug, preload: [:categories])
    Repo.one(query)
  end

  def get_collections do
    query =
      from(wtc in WorkflowTemplateCollection,
        preload: [
          :featured_providers,
          :workflow_templates
        ]
      )

    acc = %{
      collections: [],
      main_collections: []
    }

    query
    |> Repo.all()
    |> Enum.reduce(acc, fn collection, acc ->
      # Main Collections have a valid image_url
      if collection.image_url do
        Map.put(acc, :main_collections, acc[:main_collections] ++ [collection])
      else
        Map.put(acc, :collections, acc[:collections] ++ [collection])
      end
    end)
  end

  defp maybe_add_text_search_filter(query, nil = _term), do: query

  defp maybe_add_text_search_filter(query, term) when is_binary(term) do
    sanitized_term = sanitize_search_term(term)

    query
    |> where(
      [wt],
      ilike(fragment("? || ' ' || ?", wt.name, wt.short_description), ^"%#{sanitized_term}%")
    )
  end

  defp maybe_add_category_filter(query, nil = _category_ids), do: query

  defp maybe_add_category_filter(query, category_ids) do
    query
    |> join(:inner, [wt], wtc in WorkflowTemplateCategory, on: wtc.workflow_template_id == wt.id)
    |> where([_, wtc], wtc.category_id in ^category_ids)
  end

  defp maybe_add_collection_filter(query, nil = _collection_id), do: query

  defp maybe_add_collection_filter(query, collection_id) do
    query
    |> join(:inner, [wt], wtcwt in WorkflowTemplateCollectionWorkflowTemplate, on: wtcwt.workflow_template_id == wt.id)
    |> where([_, wtcwt], wtcwt.workflow_template_collection_id == ^collection_id)
  end

  defp maybe_add_provider_filter(query, nil = _provider_slug), do: query

  defp maybe_add_provider_filter(query, provider_slug) do
    sanitized_term = sanitize_search_term(provider_slug)

    query
    |> where(
      [wt],
      ilike(wt.provider_slugs, ^"%#{sanitized_term}%")
    )
  end

  defp sanitize_search_term(term) do
    like_char_regex = ~r/([\%_])/

    String.replace(term, like_char_regex, "")
  end
end
