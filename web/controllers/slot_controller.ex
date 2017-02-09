defmodule RecruitxBackend.SlotController do
  use RecruitxBackend.Web, :controller

  alias Ecto.Changeset
  alias RecruitxBackend.ChangesetManipulator
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.JSONError
  alias RecruitxBackend.Slot
  alias RecruitxBackend.SlotCancellationNotification
  alias RecruitxBackend.SlotPanelist
  alias RecruitxBackend.TimexHelper

  # plug :scrub_params, "slot" when action in [:create, :update]

  def create(conn, %{"slot_id" => slot_id, "candidate_id" => candidate_id}) do
    %{start_time: start_time, interview_type_id: interview_type_id} = Repo.get!(Slot, slot_id)
    interview_changeset = Interview.changeset(%Interview{}, %{candidate_id: candidate_id, interview_type_id: interview_type_id, start_time: start_time})
    signup_panelists_and_satisfied_criteria_for_slot = SlotPanelist.get_panelists_and_satisfied_criteria(slot_id)
    {status, result_of_db_transaction} = Repo.transaction fn ->
        # TODO: Use Ecto.Multi for performing all these within the same transaction
        {status, interview} = [interview_changeset] |> ChangesetManipulator.validate_and(Repo.custom_insert)
        if status do
          generateInterviewPanelistChangesets(interview.id, signup_panelists_and_satisfied_criteria_for_slot) |> ChangesetManipulator.validate_and(Repo.custom_insert)
          Repo.delete_all(from i in Slot, where: i.id == ^slot_id)
          Repo.delete_all(from i in SlotPanelist, where: i.slot_id == ^slot_id)
          interview
        else
          Repo.rollback(interview)
      end
    end
    conn |> sendResponseBasedOnResult(:create, status, result_of_db_transaction)
  end

  def create(conn, %{"slot" => %{"count" => count} = slot_params}) do
    create_multiple_slots(conn, Slot.changeset(%Slot{}, slot_params), count)
  end

  defp generateInterviewPanelistChangesets(_interview_id, []), do: []
  defp generateInterviewPanelistChangesets(interview_id, [{panelist_login_name, satisfied_criteria} | tail]), do: [Changeset.cast(%InterviewPanelist{}, %{interview_id: interview_id, panelist_login_name: panelist_login_name, satisfied_criteria: satisfied_criteria}, [:interview_id, :panelist_login_name, :satisfied_criteria]) | generateInterviewPanelistChangesets(interview_id, tail)]

  def sendResponseBasedOnResult(conn, action, status, interview) do
    case {action, status} do
      {:create, :ok} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", interview_path(conn, :show, interview))
        |> json("")
      {:create, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%JSONError{errors: interview})
    end
  end

  defp create_multiple_slots(conn, changeset, 1) do
    case Repo.insert(changeset) do
      {:ok, slot} ->
        conn
        |> put_status(:created)
        |> render("show.json", slot: slot)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp create_multiple_slots(conn, changeset, count) do
    case Repo.insert(changeset) do
      {:ok, _slot} ->
        create_multiple_slots(conn, changeset, count - 1)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    slot = Slot |> Repo.get(id)
    case slot do
      nil -> conn
            |> put_status(:not_found)
            |> render(ErrorView, "404.json")
      _ -> conn
          |> render("show.json", slot: slot)
    end
  end

  def delete(conn, %{"id" => id}) do
    slot = Slot |> Repo.get!(id)
    SlotCancellationNotification.execute((from s in Slot, where: s.id == ^id))
    Repo.delete!(slot)

    send_resp(conn, :no_content, "")
  end

  def index(conn, %{"interview_type_id" => interview_type_id, "previous_rounds_start_time" => previous_rounds_start_time, "role_id" => role_id}) do
    previous_rounds_end_time = previous_rounds_start_time
                                |> TimexHelper.parse("%Y-%m-%dT%H:%M:%SZ")
                                |> TimexHelper.add(1, :hours)
    slots = if interview_type_id == InterviewType.retrieve_by_name(InterviewType.p3).id
              |> Integer.to_string or interview_type_id == InterviewType.retrieve_by_name(InterviewType.leadership).id
              |> Integer.to_string do
      (from s in Slot,
            where: s.interview_type_id == ^interview_type_id and
            s.start_time >= ^previous_rounds_end_time)
            |> Repo.all
    else
      (from s in Slot,
            where: s.interview_type_id == ^interview_type_id and
            s.role_id == ^role_id and
            s.start_time >= ^previous_rounds_end_time)
            |> Repo.all
    end
    conn |> render("index.json", slots: slots)
  end

end
