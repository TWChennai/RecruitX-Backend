defmodule RecruitxBackend.Router do
  use RecruitxBackend.Web, :router

  pipeline :api  do
    plug :accepts, ["json"]
  end

  scope "/", RecruitxBackend do
    pipe_through :api

<<<<<<< 488c16813af3a09560b687b92e8da7ffea055ca5
    get "/candidates", CandidateController, :index
    post "/candidates", CandidateController, :create
    get "/roles", RoleController, :index
    get "/skills", SkillController, :index
=======
    resources "/roles", RoleController, except: [:new, :edit]
    resources "/skills", SkillController, except: [:new, :edit]
    resources "/candidates", CandidateController, except: [:new, :edit]
    resources "/interviews", InterviewController, except: [:new, :edit]
    resources "/candidate_interview_schedules", CandidateInterviewScheduleController, except: [:new, :edit]
>>>>>>> Vijay, Kausalya: Recreated the models & controllers & migrations, fixed the broken tests
  end

  # Other scopes may use custom stacks.
  # scope "/api", RecruitxBackend do
  #   pipe_through :api
  # end
end
