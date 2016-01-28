defmodule RecruitxBackend.Router do
  use RecruitxBackend.Web, :router

  pipeline :api  do
    plug :accepts, ["json"]
  end

  scope "/", RecruitxBackend do
    pipe_through :api

    resources "/roles", RoleController, only: [:index]
    resources "/skills", SkillController, only: [:index]
    resources "/candidates", CandidateController, only: [:index, :create, :show]
    resources "/interviews", InterviewController, only: [:index]
    resources "/candidate_interview_schedules", CandidateInterviewScheduleController, only: [:index]
  end

  # Other scopes may use custom stacks.
  # scope "/api", RecruitxBackend do
  #   pipe_through :api
  # end
end
