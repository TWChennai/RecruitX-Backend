defmodule RecruitxBackend.InterviewController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.ChangesetView
  alias RecruitxBackend.ErrorView
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Slot
  alias RecruitxBackend.Role
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.SlotPanelist
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.QueryFilter
  alias RecruitxBackend.Panel
  alias Timex.Date
  alias Timex.DateFormat
  alias Poison.Parser

  @api_key System.get_env("API_KEY")
  @api_url System.get_env("API_URL")

  plug :scrub_params, "interview" when action in [:update, :create]

  def default(conn, _), do: redirect conn, to: "/all_interviews"

  def index(conn, %{"panelist_login_name" => panelist_login_name, "panelist_experience" => panelist_experience,  "panelist_role" => panelist_role}) do
    interviews = Interview.get_interviews_with_associated_data
                  |> preload([:interview_type, candidate: :role, candidate: :skills]) # TODO: This line is not needed in case the request being served is json, only needed for html web version - please optimize
                  |> Panel.now_or_in_next_seven_days
                  |> Panel.default_order
                  |> Repo.all
    slots = Slot |> preload([:slot_panelists, :role, :interview_type])
                  |> Panel.now_or_in_next_seven_days
                  |> Panel.default_order
                  |> Repo.all
    retrieved_panelist_role = Role.retrieve_by_name(panelist_role)
    interviews_and_slots_with_signup_status = Panel.add_signup_eligibity_for(slots, interviews, panelist_login_name, panelist_experience, retrieved_panelist_role)
                                                |> Enum.sort(fn (first, second) -> first.signup || !second.signup end)
    conn |> render("index.json" , interviews_with_signup: interviews_and_slots_with_signup_status)
  end

  def index_all(conn, _params) do
    url = @api_url <> "/interviews/?all=true"
    response = HTTPotion.get(url, [headers: ["Authorization": @api_key]])
    case response.body |> Parser.parse do
      {:ok, interviews_and_slots_with_signup_status} -> conn |> render("index.html", interviews_with_signup: interviews_and_slots_with_signup_status, all: true, not_login: true)
    end
  end

  # TODO: Combine the above and below function and write tests
  def index_web(conn = %Plug.Conn{cookies: %{"calculated_hire_date" => calculated_hire_date, "panelist_role" => panelist_role, "username" => panelist_login_name}}, _params) do
    panelist_experience = to_string(Date.diff((calculated_hire_date |> DateFormat.parse!("%Y-%m-%d", :strftime)), Date.now, :years))
    url = @api_url <> "/interviews/?panelist_login_name=" <> panelist_login_name <> "&panelist_experience=" <> panelist_experience <> "&panelist_role=" <> panelist_role <> "&preload=true"
    response = HTTPotion.get(url, [headers: ["Authorization": @api_key]])
    case response.body |> Parser.parse do
      {:ok, interviews_and_slots_with_signup_status} -> conn |> render("index.html", interviews_with_signup: interviews_and_slots_with_signup_status, not_login: true)
    end
  end

  def index_web(conn, _params) do
    conn |> redirect(to: "/login")
  end

  def index(conn, %{"candidate_id" => candidate_id}) do
    interviews = Interview.get_interviews_with_associated_data
                  |> QueryFilter.filter(%{candidate_id: candidate_id}, Interview)
                  |> Panel.default_order
                  |> Repo.all
    conn |> render("index.json", interviews_for_candidate: interviews)
  end

  def index(conn, %{"panelist_name" => panelist_name, "page" => page}) when page == "1" or page == nil do
    interviews = InterviewPanelist.get_interviews_signed_up_by(panelist_name)
                  |> Panel.descending_order
                  |> Repo.paginate(page: page)
    last_interviews_data = Interview.get_candidates_with_all_rounds_completed |> Repo.all
    interview_entries = Enum.map(interviews.entries, fn(interview) ->
      Map.put(interview, :last_interview_status, Interview.get_last_interview_status_for(interview.candidate, last_interviews_data))
    end)
    slot_id_for_panelist = (from ip in SlotPanelist, select: ip.slot_id)
                                  |> QueryFilter.filter(%{panelist_login_name: panelist_name}, SlotPanelist)
                                  |> Repo.all
    slots = Slot
            |> preload(:slot_panelists)
            |> QueryFilter.filter(%{id: slot_id_for_panelist}, Slot)
            |> Panel.descending_order
            |> Repo.all
    interviews = Map.put(interviews, :entries, slots ++ interview_entries)
    conn |> render("index.json", interviews: interviews)
  end

  def index(conn, %{"panelist_name" => panelist_name, "page" => page}) do
    interviews = InterviewPanelist.get_interviews_signed_up_by(panelist_name)
                  |> Panel.descending_order
                  |> Repo.paginate(page: page)
    last_interviews_data = Interview.get_candidates_with_all_rounds_completed |> Repo.all
    interview_entries = Enum.map(interviews.entries, fn(interview) ->
      Map.put(interview, :last_interview_status, Interview.get_last_interview_status_for(interview.candidate, last_interviews_data))
    end)
    interviews = Map.put(interviews, :entries, interview_entries)
    conn |> render("index.json", interviews: interviews)
  end

  def index(conn, _) do
    conn |> put_status(400) |> render(RecruitxBackend.ChangesetView, "missing_param_error.json", param: "panelist_login_name/candidate_id/panelist_name/panelist_experience/panelist_role")
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
