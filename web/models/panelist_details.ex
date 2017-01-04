defmodule RecruitxBackend.PanelistDetails do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Role
  @primary_key {:panelist_login_name, :string, []}
  @derive {Phoenix.Param, key: :panelist_login_name}

  schema "panelist_details" do
    field :employee_id, :decimal

    timestamps()

    belongs_to :role, Role, references: :id
  end

  @required_fields ~w(role_id panelist_login_name employee_id)
  @optional_fields ~w()

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(Enum.map(@required_fields, &String.to_atom(&1)))
  end
end
