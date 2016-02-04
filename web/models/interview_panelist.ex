defmodule RecruitxBackend.InterviewPanelist do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.Repo

  @max_count 2

  @derive {Poison.Encoder, only: [:id, :panelist_login_name]}
  schema "interview_panelists" do
    field :panelist_login_name, :string

    belongs_to :interview, Interview

    timestamps
  end

  def get_interview_type_based_count_of_sign_ups do
    # TODO: Do we need to join on both interview and interview_type?
    # TODO: use assoc in join
    from ip in InterviewPanelist,
      join: i in Interview, on: ip.interview_id == i.id,
      group_by: ip.interview_id,
      group_by: i.interview_type_id,
      select: %{"interview_id": ip.interview_id, "signup_count": count(ip.interview_id), "interview_type": i.interview_type_id}
  end

  def get_signup_count_for_interview_id(id) do
    from ip in InterviewPanelist,
      where: ip.interview_id == ^id,
      group_by: ip.interview_id,
      select: count(ip.interview_id)
  end

  @required_fields ~w(panelist_login_name interview_id)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_format(:panelist_login_name, ~r/^[a-z]+[\sa-z]*$/i)
    |> unique_constraint(:panelist_login_name, name: :interview_panelist_login_name_index, message: "You have already signed up for this interview")
    |> validate_signup_count(:interview_id)
    |> assoc_constraint(:interview)
  end

  def validate_signup_count(existing_changeset, field) do
    id = get_field(existing_changeset, field)
    if !is_nil(id) do
      count = get_signup_count_for_interview_id(id) |> Repo.one
      if !is_nil(count) and count >= @max_count, do: existing_changeset = add_error(existing_changeset,  :signup, "More than #{@max_count} signups are not allowed")
    end
    existing_changeset
  end
end
