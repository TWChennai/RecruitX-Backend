defmodule RecruitxBackend.PageController do
  use RecruitxBackend.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

end
