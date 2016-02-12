defmodule RecruitxBackend.InterviewController do
  use RecruitxBackend.Web, :controller

  import Ecto.Query
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.QueryFilter

  plug :scrub_params, "interview" when action in [:update]

  #TODO:To use guard classes
  def index(conn, params) do
    panelist_login_name = params["panelist_login_name"]
    candidate_id = params["candidate_id"]
    panelist_name = params["panelist_name"]
    cond do
      !is_nil(panelist_login_name) ->
        get_interviews_for_signup(panelist_login_name, conn)
      !is_nil(candidate_id) ->
        get_interviews_for_candidate(candidate_id, conn)
      !is_nil(panelist_name) ->
        get_interviews_for_panelist(panelist_name, conn)
      true ->
        conn |> put_status(400) |> render("missing_param_error.json", param: "panelist_login_name")
    end
  end

  def show(conn, %{"id" => id}) do
    interview = Interview.get_interviews_with_associated_data |> Repo.get(id)
    case interview do
      nil -> conn |> put_status(:not_found) |> render(RecruitxBackend.ErrorView, "404.json")
      _ -> conn |> render("show.json", interview: interview |> Repo.preload(:feedback_images))
    end
  end

  defp get_interviews_for_candidate(id, conn) do
    interviews = Interview.get_interviews_with_associated_data
                  |> QueryFilter.filter_new(%{candidate_id: id}, Interview)
                  |> Repo.all
    conn |> render("index.json", interviews: interviews)
  end

  defp get_interviews_for_panelist(panelist_name, conn) do
    interview_id_for_panelist = (from ip in InterviewPanelist, select: ip.interview_id)
                                  |> QueryFilter.filter_new(%{panelist_login_name: panelist_name}, InterviewPanelist)
                                  |> Repo.all
    interviews = Interview.get_interviews_with_associated_data
                  |> QueryFilter.filter_new(%{id: interview_id_for_panelist}, Interview)
                  |> Interview.default_order
                  |> Repo.all
    conn |> render("index.json", interviews: interviews)
  end

  defp get_interviews_for_signup(panelist_login_name, conn) do
    interviews = Interview.get_interviews_with_associated_data |> Interview.now_or_in_next_seven_days |> Repo.all
    interviews_with_signup_status = Interview.add_signup_eligibity_for(interviews, panelist_login_name)
    conn |> render("index.json", interviews_with_signup: interviews_with_signup_status)
  end

  def update(conn, %{"id" => id, "interview" => interview_params}) do
    interview = Interview |> preload(:interview_type) |> Repo.get(id)
    changeset = Interview.changeset(interview, interview_params)
    changeset = Interview.validate_with_other_rounds(changeset)

    case Repo.update(changeset) do
      {:ok, _interview} ->
        conn
        |> render(RecruitxBackend.SuccessView, "success.json", message: "Updated successfully")
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
    end
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
  #     send_resp(conn, 200, "")
  #   else
  #     send_resp(conn, 400, "")
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
