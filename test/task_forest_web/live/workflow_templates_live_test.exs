defmodule TaskForestWeb.WorkflowTemplatesLiveTest do
  use TaskForestWeb.ConnCase

  import Phoenix.LiveViewTest
  import TaskForest.MarketplaceFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_workflow_templates(_) do
    workflow_templates = workflow_templates_fixture()
    %{workflow_templates: workflow_templates}
  end

  describe "Index" do
    setup [:create_workflow_templates]

    test "lists all workflow_templates", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/workflow_templates")

      assert html =~ "Listing Workflow templates"
    end

    test "saves new workflow_templates", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/workflow_templates")

      assert index_live |> element("a", "New Workflow templates") |> render_click() =~
               "New Workflow templates"

      assert_patch(index_live, ~p"/workflow_templates/new")

      assert index_live
             |> form("#workflow_templates-form", workflow_templates: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#workflow_templates-form", workflow_templates: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/workflow_templates")

      html = render(index_live)
      assert html =~ "Workflow templates created successfully"
    end

    test "updates workflow_templates in listing", %{
      conn: conn,
      workflow_templates: workflow_templates
    } do
      {:ok, index_live, _html} = live(conn, ~p"/workflow_templates")

      assert index_live
             |> element("#workflow_templates-#{workflow_templates.id} a", "Edit")
             |> render_click() =~
               "Edit Workflow templates"

      assert_patch(index_live, ~p"/workflow_templates/#{workflow_templates}/edit")

      assert index_live
             |> form("#workflow_templates-form", workflow_templates: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#workflow_templates-form", workflow_templates: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/workflow_templates")

      html = render(index_live)
      assert html =~ "Workflow templates updated successfully"
    end

    test "deletes workflow_templates in listing", %{
      conn: conn,
      workflow_templates: workflow_templates
    } do
      {:ok, index_live, _html} = live(conn, ~p"/workflow_templates")

      assert index_live
             |> element("#workflow_templates-#{workflow_templates.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#workflow_templates-#{workflow_templates.id}")
    end
  end

  describe "Show" do
    setup [:create_workflow_templates]

    test "displays workflow_templates", %{conn: conn, workflow_templates: workflow_templates} do
      {:ok, _show_live, html} = live(conn, ~p"/workflow_templates/#{workflow_templates}")

      assert html =~ "Show Workflow templates"
    end

    test "updates workflow_templates within modal", %{
      conn: conn,
      workflow_templates: workflow_templates
    } do
      {:ok, show_live, _html} = live(conn, ~p"/workflow_templates/#{workflow_templates}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Workflow templates"

      assert_patch(show_live, ~p"/workflow_templates/#{workflow_templates}/show/edit")

      assert show_live
             |> form("#workflow_templates-form", workflow_templates: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#workflow_templates-form", workflow_templates: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/workflow_templates/#{workflow_templates}")

      html = render(show_live)
      assert html =~ "Workflow templates updated successfully"
    end
  end
end
