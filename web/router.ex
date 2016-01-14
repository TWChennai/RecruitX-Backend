defmodule RecruitxBackend.Router do
  use RecruitxBackend.Web, :router

  pipeline :api  do
    plug :accepts, ["json"]
  end

  scope "/", RecruitxBackend do
    pipe_through :api

    get "/candidates", CandidateController, :index
    post "/candidates", CandidateController, :create
    get "/roles", RoleController, :index
    get "/skills", SkillController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", RecruitxBackend do
  #   pipe_through :api
  # end
end
