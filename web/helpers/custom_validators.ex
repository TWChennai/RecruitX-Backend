defmodule RecruitxBackend.CustomValidators do
  alias Ecto.Changeset
  alias Ecto.DateTime

  import Ecto.Changeset, only: [add_error: 3]

  def validate_date_time(existing_changeset, field) do
    value = Changeset.get_field(existing_changeset, field)
    cast_date_time = DateTime.cast(value)
    # TODO: The error is not being captured since the return value is not set back to "existing_changeset"
    if cast_date_time == :error && value != "", do: existing_changeset |> add_error(field, "is invalid")
    existing_changeset
  end
end
