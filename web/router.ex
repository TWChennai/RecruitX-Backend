defmodule RecruitxBackend.Router do
  use RecruitxBackend.Web, :router

  pipeline :api  do
    plug :accepts, ["json"]
  end

  scope "/", RecruitxBackend do
    pipe_through :api

    resources "/roles", RoleController, except: [:new, :edit]
    resources "/skills", SkillController, except: [:new, :edit]
    resources "/candidates", CandidateController, except: [:new, :edit]
    resources "/interviews", InterviewController, except: [:new, :edit]
    resources "/candidate_interview_schedules", CandidateInterviewScheduleController, except: [:new, :edit]
  end

  # Other scopes may use custom stacks.
  # scope "/api", RecruitxBackend do
  #   pipe_through :api
  # end
end
