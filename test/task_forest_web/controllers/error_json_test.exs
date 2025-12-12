defmodule TaskForestWeb.ErrorJSONTest do
  use TaskForestWeb.ConnCase, async: true

  test "renders 404" do
    assert TaskForestWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert TaskForestWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
