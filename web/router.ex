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
    plug RecruitxBackend.ApiKeyAuthenticator
    plug :accepts, ["json"]
  end

  scope "/", RecruitxBackend do
    pipe_through :browser
    get "/login", LoginController, :index
    get "/homepage", InterviewController, :index_web
  end

  # TODO: make "web" use the root namespace ("/") and "API" use the "/api" namespace

  scope "/", RecruitxBackend do
    pipe_through :api

    resources "/roles", RoleController, only: [:index]
    resources "/is_recruiter", JigsawController, only: [:show]
    resources "/skills", SkillController, only: [:index]
    resources "/candidates", CandidateController, only: [:index, :create, :show, :update]
    resources "/candidates/:candidate_id/interviews", InterviewController, only: [:index]
    resources "/panelists/:panelist_name/interviews", InterviewController, only: [:index]
    resources "/interview_types", InterviewTypeController, only: [:index]
    resources "/interviews", InterviewController, only: [:index, :show, :update, :create]
    resources "/interviews/:interview_id/feedback_images", FeedbackImageController, only: [:create, :show]
    resources "/panelists", PanelistController, only: [:create, :show, :delete]
    resources "/remove_panelists", PanelistController, only: [:delete]
    resources "/decline_slot", PanelistController, only: [:delete]
    resources "/interview_statuses", InterviewStatusController, only: [:index]
    resources "/pipeline_statuses", PipelineStatusController, only: [:index]
    resources "/sos_email", SosEmailController, only: [:index]
    resources "/slots", SlotController, only: [:create, :show, :index]
    resources "/slot_to_interview", SlotController, only: [:create]
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
