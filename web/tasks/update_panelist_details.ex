defmodule RecruitxBackend.UpdatePanelistDetails do

  alias RecruitxBackend.JigsawController
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Role
  alias RecruitxBackend.PanelistDetails
  alias Poison.Parser

  @jigsaw_url System.get_env("JIGSAW_URL")

  def execute(panelist_login_name) do
    panelist_details = PanelistDetails |> Repo.get(panelist_login_name)
    case panelist_details do
      nil -> panelist_login_name |> update_panelist_details
      _ -> :do_nothing
    end
  end

  defp update_panelist_details(panelist_login_name) do
    response = "#{@jigsaw_url}/people/#{panelist_login_name}" |> JigsawController.get_data_safely
    case response.status_code do
      200 ->
        {:ok, %{"employeeId" => employee_id, "role" => %{"name" => role}}} = response.body |> Parser.parse
        PanelistDetails.changeset(%PanelistDetails{},
          %{panelist_login_name: panelist_login_name, employee_id: employee_id, role_id: (role |> Role.get_role).id})
        |> Repo.insert
      400 -> :do_nothing
    end
  end
end
