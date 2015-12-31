defmodule RecruitxBackend.Router do
  use RecruitxBackend.Web, :router

  # TODO: Probably review this block and delete it since you are only supporting JSON requests
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api  do
    plug :accepts, ["json"]
  end

  scope "/", RecruitxBackend do
    pipe_through :api # Use the default browser stack

    get "/candidates", CandidateController, :index

    post "/candidates", CandidateController, :create

  end

  # Other scopes may use custom stacks.
  # scope "/api", RecruitxBackend do
  #   pipe_through :api
  # end
end
