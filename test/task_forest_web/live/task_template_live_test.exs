defmodule TaskForestWeb.TaskTemplateLiveTest do
  use TaskForestWeb.ConnCase

  import Phoenix.LiveViewTest
  import TaskForest.TasksFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_task_template(_) do
    task_template = task_template_fixture()
    %{task_template: task_template}
  end

  describe "Index" do
    setup [:create_task_template]

    test "lists all task_templates", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/task_templates")

      assert html =~ "Listing Task templates"
    end

    test "saves new task_template", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/task_templates")

      assert index_live |> element("a", "New Task template") |> render_click() =~
               "New Task template"

      assert_patch(index_live, ~p"/task_templates/new")

      assert index_live
             |> form("#task_template-form", task_template: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#task_template-form", task_template: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/task_templates")

      html = render(index_live)
      assert html =~ "Task template created successfully"
    end

    test "updates task_template in listing", %{conn: conn, task_template: task_template} do
      {:ok, index_live, _html} = live(conn, ~p"/task_templates")

      assert index_live
             |> element("#task_templates-#{task_template.id} a", "Edit")
             |> render_click() =~
               "Edit Task template"

      assert_patch(index_live, ~p"/task_templates/#{task_template}/edit")

      assert index_live
             |> form("#task_template-form", task_template: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#task_template-form", task_template: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/task_templates")

      html = render(index_live)
      assert html =~ "Task template updated successfully"
    end

    test "deletes task_template in listing", %{conn: conn, task_template: task_template} do
      {:ok, index_live, _html} = live(conn, ~p"/task_templates")

      assert index_live
             |> element("#task_templates-#{task_template.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#task_templates-#{task_template.id}")
    end
  end

  describe "Show" do
    setup [:create_task_template]

    test "displays task_template", %{conn: conn, task_template: task_template} do
      {:ok, _show_live, html} = live(conn, ~p"/task_templates/#{task_template}")

      assert html =~ "Show Task template"
    end

    test "updates task_template within modal", %{conn: conn, task_template: task_template} do
      {:ok, show_live, _html} = live(conn, ~p"/task_templates/#{task_template}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Task template"

      assert_patch(show_live, ~p"/task_templates/#{task_template}/show/edit")

      assert show_live
             |> form("#task_template-form", task_template: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#task_template-form", task_template: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/task_templates/#{task_template}")

      html = render(show_live)
      assert html =~ "Task template updated successfully"
    end
  end
end
