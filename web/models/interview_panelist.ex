defmodule RecruitxBackend.InterviewPanelist do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.Repo

  @max_count 2

  schema "interview_panelists" do
    field :panelist_login_name, :string

    belongs_to :interview, Interview

    timestamps
  end

  def get_interview_type_based_count_of_sign_ups do
    from ip in InterviewPanelist,
      join: i in assoc(ip, :interview),
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
    |> validate_signup_count()
    |> validate_panelist_has_not_interviewed_candidate()
    |> unique_constraint(:panelist_login_name, name: :interview_panelist_login_name_index, message: "You have already signed up for this interview")
    |> assoc_constraint(:interview)
  end

  #TODO:'You have already signed up for the same interview' constraint error never occurs as it is handled here at changeset level itself
  defp validate_panelist_has_not_interviewed_candidate(existing_changeset) do
    interview_id = get_field(existing_changeset, :interview_id)
    panelist_login_name = get_field(existing_changeset, :panelist_login_name)
    if !is_nil(interview_id) and !is_nil(panelist_login_name) do
      interview = Interview |> Repo.get(interview_id)
      candidate_ids_interviewed = (Interview.get_candidate_ids_interviewed_by(panelist_login_name) |> Repo.all)
      if !is_nil(interview) and !Interview.has_panelist_not_interviewed_candidate(interview, candidate_ids_interviewed) do
        existing_changeset = add_error(existing_changeset, :signup, "You have already signed up an interview for this candidate")
      end
    end
    existing_changeset
  end

  defp validate_signup_count(existing_changeset) do
    id = get_field(existing_changeset, :interview_id)
    if !is_nil(id) and !Interview.is_signup_lesser_than(id, @max_count) do
      existing_changeset = add_error(existing_changeset, :signup_count, "More than #{@max_count} signups are not allowed")
    end
    existing_changeset
  end
end
