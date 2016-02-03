defmodule RecruitxBackend.InterviewController do
  use RecruitxBackend.Web, :controller

  import Ecto.Query
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.QueryFilter

  # TODO: Uncomment if/when implementing the create/update actions
  # plug :scrub_params, "interview" when action in [:create, :update]

  def index(conn, params) do
    try do
      panelist_login_name = params["panelist_login_name"]
      if is_nil(panelist_login_name),do: throw {:missing_param_error,"panelist_login_name"}

      interviews = (from cis in Interview,
                    join: c in assoc(cis, :candidate),
                    join: cs in assoc(c, :candidate_skills),
                    join: i in assoc(cis, :interview_type),
                    preload: [:interview_type, candidate: {c, [candidate_skills: cs]}],
                    select: cis) |> QueryFilter.filter(%Interview{}, params, [:candidate_id]) |> Repo.all

      interviews_with_signup_status = add_signup_eligibity_for(interviews, panelist_login_name)
      render(conn, "index.json", interviews: interviews_with_signup_status)
    catch {:missing_param_error, param} ->
      render(conn|> put_status(:unprocessable_entity), "missing_param_error.json", param: param)
    end
  end

  def show(conn, %{"id" => id}) do
    interview = (from i in Interview,
      join: c in assoc(i, :candidate),
      join: cs in assoc(c, :candidate_skills),
      join: it in assoc(i, :interview_type),
      preload: [:interview_type, candidate: {c, candidate_skills: cs}],
      select: i) |> Repo.get(id)
    render(conn, "show.json", interview: interview)
  end

  def add_signup_eligibity_for(interviews, panelist_login_name) do
    candidate_ids_interviewed = Interview.get_candidate_ids_interviewed_by(panelist_login_name) |> Repo.all
    Enum.map(interviews, fn(interview) ->
      signup_eligiblity = has_panelist_not_interviewed_candidate(candidate_ids_interviewed,interview) and is_signup_lesser_than(interview, 4)
      Map.put(interview, :signup, signup_eligiblity)
    end)
  end

  def has_panelist_not_interviewed_candidate(candidate_ids_interviewed, interview) do
    !Enum.member?(candidate_ids_interviewed, interview.candidate_id)
  end

  def is_signup_lesser_than(interview, max_count) do
    signup_counts = InterviewPanelist.get_interview_type_based_count_of_sign_ups |> Repo.all
    result = Enum.filter(signup_counts, fn(i) -> i.interview_id == interview.id end)
    result != [] and List.first(result).signup_count < max_count
  end

  # def create(conn, %{"interview" => interview_params}) do
  #   changeset = Interview.changeset(%Interview{}, interview_params)
  #
  #   # case Repo.insert(changeset) do
  #   #   {:ok, interview} ->
  #   #     conn
  #   #     |> put_status(:created)
  #   #     |> put_resp_header("location", interview_path(conn, :show, interview))
  #   #     # |> render("show.json", interview: interview)
  #   #   {:error, changeset} ->
  #   #     conn
  #   #     |> put_status(:unprocessable_entity)
  #   #     # |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
  #   # end
  #   if changeset.valid? do
  #     Repo.insert(changeset)
  #     # TODO: Need to send JSON response
  #     send_resp(conn, 200, "")
  #   else
  #     # TODO: Need to send JSON response
  #     send_resp(conn, 400, "")
  #   end
  # end

  # def show(conn, %{"id" => id}) do
  #   interview = Repo.get!(Interview, id)
  #   render(conn, "show.json", interview: interview)
  # end
  #
  # def update(conn, %{"id" => id, "interview" => interview_params}) do
  #   interview = Repo.get!(Interview, id)
  #   changeset = Interview.changeset(interview, interview_params)
  #
  #   case Repo.update(changeset) do
  #     {:ok, interview} ->
  #       render(conn, "show.json", interview: interview)
  #     {:error, changeset} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
  #   end
  # end
  #
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
