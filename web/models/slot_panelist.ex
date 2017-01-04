defmodule RecruitxBackend.SlotPanelist do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Slot
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Role
  alias RecruitxBackend.AppConstants
  alias RecruitxBackend.SignUpEvaluator


  schema "slot_panelists" do
    field :panelist_login_name, :string
    field :satisfied_criteria, :string

    belongs_to :slot, Slot

    timestamps()
  end

  @required_fields ~w(panelist_login_name slot_id)
  @optional_fields ~w(satisfied_criteria)

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(Enum.map(@required_fields, &String.to_atom(&1)))
    |> validate_format(:panelist_login_name, AppConstants.name_format)
    |> validate_sign_up_for_slot(params)
    |> unique_constraint(:panelist_login_name, name: :slot_panelist_login_name_index, message: "You have already signed up for this slot")
    |> assoc_constraint(:slot, message: "Slot does not exist")
  end

  def get_interview_type_based_count_of_sign_ups do
    from sp in __MODULE__,
      join: s in assoc(sp, :slot),
      group_by: sp.slot_id,
      group_by: s.interview_type_id,
      select: %{"slot_id": sp.slot_id, "signup_count": count(sp.slot_id), "interview_type": s.interview_type_id}
  end

  defp validate_sign_up_for_slot(existing_changeset, params) do
    slot_id = get_field(existing_changeset, :slot_id)
    panelist_login_name = get_field(existing_changeset, :panelist_login_name)
    panelist_experience = params["panelist_experience"]
    panelist_role = params["panelist_role"]
    if existing_changeset.valid? do
      slot = (Slot) |> Repo.get(slot_id)
      if !is_nil(slot) do
        retrieved_panelist_role = Role.retrieve_by_name(panelist_role)
        sign_up_data_container = SignUpEvaluator.populate_sign_up_data_container(panelist_login_name, Decimal.new(panelist_experience), retrieved_panelist_role, true)
        sign_up_evaluation_status = SignUpEvaluator.evaluate(sign_up_data_container, slot, Role.ba_and_pm_list)
        existing_changeset |> update_changeset(sign_up_evaluation_status, sign_up_evaluation_status.valid?)
      else
        existing_changeset
      end
    else
      existing_changeset
    end
  end

  defp update_changeset(existing_changeset, sign_up_evaluation_status, true) do
    existing_changeset |> put_change(:satisfied_criteria, sign_up_evaluation_status.satisfied_criteria)
  end

  defp update_changeset(existing_changeset, sign_up_evaluation_status, false) do
    Enum.reduce(sign_up_evaluation_status.errors, existing_changeset, fn({field_name, description}, acc) ->
      add_error(acc, field_name, description)
    end)
  end

  def get_panelists_and_satisfied_criteria(slot_id) do
    (from sp in __MODULE__,
    where: sp.slot_id == ^slot_id,
    select: {sp.panelist_login_name, sp.satisfied_criteria})
      |> Repo.all
  end

end
