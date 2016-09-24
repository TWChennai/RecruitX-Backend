defmodule RecruitxBackend.UpdateTeam do

  alias Poison.Parser
  alias RecruitxBackend.JigsawController
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Team

  @jigsaw_url System.get_env("JIGSAW_URL")

  def execute(employee_id, interview_panelist_id) do
    response = "#{@jigsaw_url}/assignments?employee_ids[]=#{employee_id}&current_only=true" |> JigsawController.get_data_safely
    case response.status_code do
      200 ->
        {:ok, %{"project" => %{"name" => project_name}}} = response.body |> Parser.parse
        case project_name |> Team.retrieve_by_name do
          nil -> Team.changeset(%Team{},%{name: project_name}) |> Repo.insert
          _ -> :do_nothing
        end
      400 -> :do_nothing
    end
  end
end
