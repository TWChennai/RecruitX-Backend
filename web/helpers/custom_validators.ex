defmodule RecruitxBackend.CustomValidators do
  alias Ecto.Changeset
  alias Ecto.DateTime

  def validate_date_time(existing_changeset, field) do
    value = Changeset.get_field(existing_changeset, field)
    cast_date_time = DateTime.cast(value)
    if cast_date_time == :error && value != "", do: Changeset.add_error(existing_changeset, :"#{field}", "is invalid")
    existing_changeset
  end
end
