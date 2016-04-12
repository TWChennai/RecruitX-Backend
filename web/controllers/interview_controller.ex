defmodule RecruitxBackend.InterviewController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.ChangesetView
  alias RecruitxBackend.ErrorView
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.QueryFilter

  plug :scrub_params, "interview" when action in [:update, :create]

  def index(conn, %{"panelist_login_name" => panelist_login_name, "panelist_experience" => panelist_experience,  "panelist_role" => panelist_role}) do
    interviews = Interview.get_interviews_with_associated_data
                  |> Interview.now_or_in_next_seven_days
                  |> Interview.default_order
                  |> Repo.all
    interviews_with_signup_status = Interview.add_signup_eligibity_for(interviews, panelist_login_name, panelist_experience, panelist_role)
    conn |> render("index.json", interviews_with_signup: interviews_with_signup_status)
  end

  def index(conn, %{"candidate_id" => candidate_id}) do
    interviews = Interview.get_interviews_with_associated_data
                  |> QueryFilter.filter(%{candidate_id: candidate_id}, Interview)
                  # TODO: Shouldn't this be ordered?
                  |> Repo.all
    conn |> render("index.json", interviews_for_candidate: interviews)
  end

  def index(conn, %{"panelist_name" => panelist_name, "page" => page}) do
    interview_id_for_panelist = (from ip in InterviewPanelist, select: ip.interview_id)
                                  |> QueryFilter.filter(%{panelist_login_name: panelist_name}, InterviewPanelist)
                                  |> Repo.all
    interviews = Interview.get_interviews_with_associated_data
                  |> QueryFilter.filter(%{id: interview_id_for_panelist}, Interview)
                  |> Interview.descending_order
                  |> Repo.paginate(page: page)
    last_interviews_data = Interview.get_candidates_with_all_rounds_completed |> Repo.all
    interview_entries = Enum.map(interviews.entries, fn(interview) ->
      Map.put(interview, :last_interview_status, Interview.get_last_interview_status_for(interview.candidate, last_interviews_data))
    end)
    interviews = Map.put(interviews, :entries, interview_entries)
    conn |> render("index.json", interviews: interviews)
  end

  def index(conn, _) do
    conn |> put_status(400) |> render("missing_param_error.json", param: "panelist_login_name/candidate_id/panelist_name/panelist_experience/panelist_role")
  end

  def show(conn, %{"id" => id}) do
    interview = Interview.get_interviews_with_associated_data |> Repo.get(id)
    case interview do
      nil -> conn |> put_status(:not_found) |> render(ErrorView, "404.json")
      _ ->
        previous_interview_status = Interview.get_last_completed_rounds_status_for(interview.candidate_id, interview.start_time)
        interview = Map.put(interview, :previous_interview_status, previous_interview_status)
        conn |> render("show.json", interview: interview |> Repo.preload(:feedback_images))
    end
  end

  def update(conn, %{"id" => id, "interview" => interview_params}) do
    interview = Interview |> preload(:interview_type) |> Repo.get(id)
    changeset = Interview.changeset(interview, interview_params)
    # TODO: Can't this validation be moved into the changeset method itself? The second param can be obtained from the changeset itself
    changeset = Interview.validate_with_other_rounds(changeset)

    case Repo.update(changeset) do
      {:ok, interview} ->
        conn
        |> put_status(:ok)
        |> render("success.json", interview: interview)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  def create(conn, %{"interview" => interview_params}) do
    interview_type = InterviewType |> Repo.get(interview_params["interview_type_id"])
    changeset = Interview.changeset(%Interview{}, interview_params)
    # TODO: Can't this validation be moved into the changeset method itself? The second param can be obtained from the changeset itself
    changeset = Interview.validate_with_other_rounds(changeset, interview_type)

    case Repo.insert(changeset) do
      {:ok, interview} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", interview_path(conn, :show, interview))
        |> render("success.json", interview: interview)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  # def delete(conn, %{"id" => id}) do
  #   interview = Repo.get!(Interview, id)
  #
  #   # Here we use delete! (with a bang) because we expect
  #   # it to always work (and if it does not, it will raise).
  #   Repo.delete!(interview)
  #
  #   send_resp(conn, :no_content, "")
  # end
end
