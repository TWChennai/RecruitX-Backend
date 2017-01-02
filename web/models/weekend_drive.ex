defmodule RecruitxBackend.WeekendDrive do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Timer

  schema "weekend_drives" do
    field :start_date, Timex.Ecto.Date
    field :end_date, Timex.Ecto.Date
    field :no_of_candidates, :integer
    field :no_of_panelists, :integer
    belongs_to :role, RecruitxBackend.Role

    timestamps
  end

  @required_fields ~w(start_date end_date no_of_candidates role_id)
  @optional_fields ~w(no_of_panelists)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> assoc_constraint(:role)
    |> Timer.is_in_future(:start_date)
    |> Timer.is_after(:end_date, :start_date)
  end
end
