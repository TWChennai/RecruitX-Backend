defmodule RecruitxBackend.UpdateTeam do

  alias Poison.Parser
  alias RecruitxBackend.JigsawController
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Team

  @jigsaw_url System.get_env("JIGSAW_URL")

  def execute(employee_id, _interview_panelist_id) do
    response = "#{@jigsaw_url}/assignments?employee_ids[]=#{employee_id}&current_only=true" |> JigsawController.get_data_safely
    case response.status_code do
      200 ->
        case response.body |> Parser.parse do
          {:ok, []} -> update("Other Projects")
          {:ok, [%{"project" => %{"name" => project_name}} | _other_projects]} -> update(project_name)
          _ -> :do_nothing
        end
      _ -> :do_nothing
    end
  end

  defp update(project_name) do
    project = project_name |> Team.retrieve_by_name
    case project do
      nil -> Team.changeset(%Team{},%{name: project_name}) |> Repo.insert!
      _ -> project
    end
  end
end
