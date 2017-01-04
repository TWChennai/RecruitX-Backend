defmodule RecruitxBackend.UpdateTeamDetails do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.Repo

  schema "update_team_details" do
    field :panelist_login_name, :string
    field :processed, :boolean

    belongs_to :interview_panelist, InterviewPanelist

    timestamps()
  end

  @required_fields ~w(panelist_login_name interview_panelist_id processed)
  @optional_fields ~w()

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(Enum.map(@required_fields, &String.to_atom(&1)))
    |> unique_constraint(:panelist_login_id, name: :interview_panelist_login_id_index, message: "Details are already updated")
  end
end
