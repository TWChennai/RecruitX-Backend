defmodule RecruitxBackend.Router do
  use RecruitxBackend.Web, :router

  pipeline :api  do
    plug :accepts, ["json"]
  end

  scope "/", RecruitxBackend do
    pipe_through :api

    resources "/roles", RoleController, only: [:index]
    resources "/is_recruiter", JigsawController, only: [:show]
    resources "/skills", SkillController, only: [:index]
    resources "/candidates", CandidateController, only: [:index, :create, :show]
    resources "/candidates/:candidate_id/interviews", InterviewController, only: [:index]
    resources "/panelists/:panelist_name/interviews", InterviewController, only: [:index]
    resources "/interview_types", InterviewTypeController, only: [:index]
    resources "/interviews", InterviewController, only: [:index, :show]
    resources "/interviews/:interview_id/feedback_images", FeedbackImageController, only: [:create, :show]
    resources "/panelists", PanelistController, only: [:create, :show]
    resources "/interview_statuses", InterviewStatusController, only: [:index]
  end

  # Other scopes may use custom stacks.
  # scope "/api", RecruitxBackend do
  #   pipe_through :api
  # end
end
