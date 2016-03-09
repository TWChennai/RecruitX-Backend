defmodule RecruitxBackend.PanelistController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.ChangesetManipulator
  alias RecruitxBackend.JSONError

  def create(conn, %{"interview_panelist" => post_params}) do
    interview_panelist_changeset = InterviewPanelist.changeset(%InterviewPanelist{}, post_params)
    try do
      {status, interview_panelist} = ChangesetManipulator.insertChangesets([interview_panelist_changeset])
      conn |> sendResponseBasedOnResult(:create, status, interview_panelist)
    catch {status, error} ->
      conn |> sendResponseBasedOnResult(:create, status, error)
    end
  end

  def sendResponseBasedOnResult(conn, action, status, response) do
    case {action, status} do
      {:create, :ok} ->
        conn
          |> put_status(:created)
          |> put_resp_header("location", panelist_path(conn, :show, response))
          |> json("")
      {:create, _} ->
        conn
          |> put_status(:unprocessable_entity)
          |> json(%JSONError{errors: response})
    end
  end

  def delete(conn, %{"id" => id}) do
    Repo.delete_all(from i in InterviewPanelist, where: i.id == ^id)
    send_resp(conn, :no_content, "")
  end
end
