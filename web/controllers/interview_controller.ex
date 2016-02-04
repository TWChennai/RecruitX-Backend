defmodule RecruitxBackend.InterviewController do
  use RecruitxBackend.Web, :controller

  import Ecto.Query
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.QueryFilter

  # TODO: Uncomment if/when implementing the create/update actions
  # plug :scrub_params, "interview" when action in [:create, :update]

  def index(conn, params) do
    panelist_login_name = params["panelist_login_name"]
    candidate_id = params["id"]
    if !is_nil(panelist_login_name), do: conn = get_interviews_for_signup(panelist_login_name, conn)
    if !is_nil(candidate_id), do: conn = get_interviews_for_candidate(candidate_id, conn)
    render(conn|> put_status(400), "missing_param_error.json", param: "error")
  end

  def show(conn, %{"id" => id}) do
    # TODO: Handle scenario of 'Repo.get!' - ie when an invalid/missing record is hit
    interview = (from i in Interview,
      join: c in assoc(i, :candidate),
      join: cs in assoc(c, :candidate_skills),
      join: it in assoc(i, :interview_type),
      # TODO: Remove preload of master data (interview_type)
      preload: [:interview_type, candidate: {c, candidate_skills: cs}],
      select: i) |> Repo.get(id)
    render(conn, "show.json", interview: interview)
  end

  defp get_interviews_for_candidate(id, conn) do
      interviews = Interview.get_interviews_with_associated_data
                    |> QueryFilter.filter_new(%{candidate_id: [id]})
                    |> Repo.all
      render(conn, "index.json", interviews: interviews)
  end

  defp get_interviews_for_signup(panelist_login_name, conn) do
      interviews = Interview.get_interviews_with_associated_data |> Repo.all
      interviews_with_signup_status = add_signup_eligibity_for(interviews, panelist_login_name)
      render(conn, "index.json", interviews_with_signup: interviews_with_signup_status)
  end

  def add_signup_eligibity_for(interviews, panelist_login_name) do
    candidate_ids_interviewed = Interview.get_candidate_ids_interviewed_by(panelist_login_name) |> Repo.all
    Enum.map(interviews, fn(interview) ->
      # TODO: Can the "behaviour" (that the interview cannot accept any more signups) be on the model itself as a single method?
      # TODO: Move the magic number (4) into the db
      # TODO: Could we make this into a validation also? (UI-agnosticity will mandate that be done)
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
