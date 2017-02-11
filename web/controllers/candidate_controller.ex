defmodule RecruitxBackend.CandidateController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.ChangesetView
  alias RecruitxBackend.ErrorView
  alias RecruitxBackend.Interview
  alias RecruitxBackend.JSONError
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.JSONErrorReason
  alias Swoosh.Templates
  alias RecruitxBackend.MailHelper
  alias Ecto.Multi

  # TODO: Need to fix the spec to pass context "invalid params" and check whether scrub_params is needed
  plug :scrub_params, "candidate" when action in [:create, :update]

  def index(conn, params) do
    candidates = Candidate.get_candidates_in_fifo_order
                 |> Repo.paginate(params)
    render(conn, "index.json", candidates: candidates)
  end

  @lint {Credo.Check.Refactor.ABCSize, false}
  def create(conn, %{"candidate" => %{"skill_ids" => skill_ids, "interview_rounds" => interview_rounds} = post_params}) when skill_ids != [] and interview_rounds != [] do
      result = Repo.transaction fn ->
        candidate_insert_result = Candidate.changeset(%Candidate{}, post_params) |> Repo.insert
        case candidate_insert_result do
          {:ok, candidate} -> multi = Multi.new
                              |> Multi.append(insertSkills(candidate, skill_ids))
                              |> Multi.append(insertInterviews(candidate, interview_rounds))
                              |> Repo.transaction
                              case multi do
                                {:ok, _} -> candidate
                                {:error, _, changeset, _} -> Repo.rollback(get_error_response(changeset))
                              end
          {:error, changeset} -> Repo.rollback(get_error_response(changeset))
        end
      end
      {transaction_status, result_of_db_transaction} = case result do
        {:error, _, changeset, _} -> get_error_response(changeset)
        {:error, changeset} -> {:error, changeset}
        {:ok, candidate} -> {:ok, candidate}
        end
      conn |> sendResponseBasedOnResult(:create, transaction_status, result_of_db_transaction)
  end

  def create(conn, %{"candidate" => %{"skill_ids" => skill_ids}}) when skill_ids != [] do
    conn
    |> put_status(:unprocessable_entity)
    |> render(ErrorView, "bad_request.json", %{error: %{interview_rounds: ["missing/empty required key"]}})
  end

  def create(conn, %{"candidate" => %{"interview_rounds" => interview_rounds}}) when interview_rounds != [] do
    conn
    |> put_status(:unprocessable_entity)
    |> render(ErrorView, "bad_request.json", %{error: %{skill_ids: ["missing/empty required key"]}})
  end

  def create(conn, %{"candidate" => _post_params}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(ErrorView, "bad_request.json", %{error: %{skill_ids: ["missing/empty required key"], interview_rounds: ["missing/empty required key"]}})
   end

  def show(conn, %{"id" => id}) do
    candidate = Candidate
                |> preload(:candidate_skills)
                |> Repo.get(id)
    case candidate do
      nil -> conn |> put_status(:not_found) |> render(ErrorView, "404.json")
      _ -> conn |> render("show.json", candidate: candidate)
    end
  end

  def sendResponseBasedOnResult(conn, action, status, response) do
    case {action, status} do
      {:create, :ok} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", candidate_path(conn, :show, response))
        |> json("")
      {:create, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%JSONError{errors: response})
    end
  end

  def update(conn, %{"id" => id, "candidate" => candidate_params}) do
    candidate = Candidate |> Repo.get(id)
    case candidate do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(ErrorView, "404.json")
      _ ->
        changeset = Candidate.changeset(candidate, candidate_params)
        case Repo.update(changeset) do
          {:ok, candidate} ->
            pipeline_status_id = candidate_params["pipeline_status_id"]
            if !is_nil(pipeline_status_id) do
              closed_pipeline_status_id = PipelineStatus.retrieve_by_name(PipelineStatus.closed).id
              if pipeline_status_id == closed_pipeline_status_id do
                # TODO: Combine the two following calls into a single one - and possibly push to the db
                last_completed_round_start_time = Interview.get_last_completed_rounds_start_time_for(id)
                Interview.delete_successive_interviews_and_panelists(id, last_completed_round_start_time) |> Repo.delete_all
                send_feedback_email(id)
              end
            end
            conn |> render("update.json", candidate: candidate)
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(ChangesetView, "error.json", changeset: changeset)
        end
    end
  end

  defp send_feedback_email(id) do
    candidate = Candidate.get_candidate_by_id(id) |> Repo.one
    email_content = Templates.consolidated_feedback(candidate)

    MailHelper.deliver(%{
      subject: "[RecruitX] Consolidated Feedback - #{candidate.first_name} #{candidate.last_name}",
      to: System.get_env("CONSOLIDATED_FEEDBACK_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
      html_body: email_content
    })
  end

  defp insertSkills(candidate, skill_ids), do: candidate |> generateCandidateSkillChangesets(skill_ids, Multi.new)

  defp insertInterviews(candidate, interview_rounds), do: candidate |> generateCandidateInterviewRoundChangesets(interview_rounds, Multi.new)

  defp generateCandidateSkillChangesets(_candidate, [], acc), do: acc

  defp generateCandidateSkillChangesets(candidate, [head | tail], acc), do: generateCandidateSkillChangesets(candidate, tail, acc |> Multi.insert(String.to_atom("skill_#{Enum.count(tail)}"), CandidateSkill.changeset(%CandidateSkill{}, %{candidate_id: candidate.id, skill_id: head})))

  defp generateCandidateInterviewRoundChangesets(_candidate, [], acc), do: acc

  defp generateCandidateInterviewRoundChangesets(candidate, [head | tail], acc), do: generateCandidateInterviewRoundChangesets(candidate, tail, acc |> Multi.insert(String.to_atom("interview_#{Enum.count(tail)}"), Interview.changeset(%Interview{}, %{candidate_id: candidate.id, interview_type_id: head["interview_type_id"], start_time: head["start_time"]})))

  defp get_key_value({key, {value, _args}}), do: {key, value}
  defp get_key_value({key, value}), do: {key, value}

  defp get_error_response(changeset) do
    {key, value} = get_key_value(Enum.at(changeset.errors, 0))
    [%JSONErrorReason{field_name: key, reason: value}]
  end

  #
  # def delete(conn, %{"id" => id}) do
  #   candidate = Repo.get!(Candidate, id)
  #
  #   # Here we use delete! (with a bang) because we expect
  #   # it to always work (and if it does not, it will raise).
  #   Repo.delete!(candidate)
  #
  #   send_resp(conn, :no_content, "")
  # end
end
