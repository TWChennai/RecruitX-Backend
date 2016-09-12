defmodule RecruitxBackend.Router do
  use RecruitxBackend.Web, :router

  pipeline :browser do
    plug :accepts, ~w(html)
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api  do
    plug :accepts, ["json"]
  end

  scope "/", RecruitxBackend do
    pipe_through :browser
    get "/login", LoginController, :index
    get "/my_interviews", InterviewController, :index_web
    get "/all_interviews", InterviewController, :index_all
    get "/", InterviewController, :default
  end

  # TODO: make "web" use the root namespace ("/") and "API" use the "/api" namespace

  scope "/", RecruitxBackend do
    pipe_through :api

    resources "/panelists", PanelistController, only: [:create, :show, :delete]
    resources "/candidates", CandidateController, only: [:index, :create, :show, :update]
  end

  if Mix.env == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview, [base_path: "/dev/mailbox"]
    end
  end

  if Mix.env == :test do
    scope "/test" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview, [base_path: "/test/mailbox"]
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", RecruitxBackend do
  #   pipe_through :api
  # end
end
