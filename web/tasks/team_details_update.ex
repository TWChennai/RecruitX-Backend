defmodule RecruitxBackend.TeamDetailsUpdate do
  import Ecto.Query

  alias RecruitxBackend.UpdateTeamDetails
  alias RecruitxBackend.UpdateTeam
  alias RecruitxBackend.UpdatePanelistDetails
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.Repo

  def execute do
    Repo.all(from utd in UpdateTeamDetails, where: utd.processed == false)
      |> Enum.each(&update(&1))
  end

  def update(new_interview_panelist) do
    case new_interview_panelist.panelist_login_name |> UpdatePanelistDetails.execute do
      :error -> :do_nothing
      %{employee_id: employee_id} ->
            case employee_id |> UpdateTeam.execute(new_interview_panelist.interview_panelist_id) do
              %{id: team_id} ->
                Repo.update(InterviewPanelist.changeset(Repo.get!(InterviewPanelist, new_interview_panelist.interview_panelist_id), %{"team_id" => team_id}))
                Repo.update(UpdateTeamDetails.changeset(Repo.get!(UpdateTeamDetails, new_interview_panelist.id), %{processed: true}))
              _ -> :do_nothing
            end
            end
  end

  def update_in_background(panelist_login_name, interview_panelist_id) do
    Task.async(fn -> %UpdateTeamDetails{}
      |> UpdateTeamDetails.changeset(%{"panelist_login_name" => panelist_login_name, "interview_panelist_id" => interview_panelist_id, "processed" => false})
      |> Repo.insert! #soft insert
      |> update end)
  end
end
