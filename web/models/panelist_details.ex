defmodule RecruitxBackend.PanelistDetails do
  use RecruitxBackend.Web, :model

  @primary_key {:panelist_login_name, :string, []}
  @derive {Phoenix.Param, key: :panelist_login_name}

  schema "panelist_details" do
    field :employee_id, :decimal

    timestamps

    belongs_to :role, Role, references: :id
  end

  @required_fields ~w(role_id panelist_login_name employee_id)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
