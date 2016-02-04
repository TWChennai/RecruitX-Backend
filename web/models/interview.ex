defmodule RecruitxBackend.Interview do
  use RecruitxBackend.Web, :model

  alias Ecto.DateTime
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.InterviewPanelist

  schema "interviews" do
    field :start_time, DateTime
    belongs_to :candidate, Candidate
    belongs_to :interview_type, InterviewType

    timestamps

    has_many :interview_panelist, InterviewPanelist
  end

  @required_fields ~w(candidate_id interview_type_id start_time)
  @optional_fields ~w()

  def now_or_in_future(query) do
    from i in query, where: i.start_time >= ^DateTime.utc
  end

  def get_candidate_ids_interviewed_by(panelist_login_name) do
    #TODO: Use assoc in join
    from ip in InterviewPanelist,
      where: ip.panelist_login_name == ^panelist_login_name,
      join: i in Interview, on: ip.interview_id == i.id,
      group_by: i.candidate_id,
      select: i.candidate_id
  end

  def get_interviews_with_associated_data do
    (from cis in Interview,
      join: c in assoc(cis, :candidate),
      join: cs in assoc(c, :candidate_skills),
      join: i in assoc(cis, :interview_type),
      # TODO: Remove preload of master data (interview_type)
      preload: [:interview_type, candidate: {c, [candidate_skills: cs]}],
      select: cis)
  end

  def get_interviews_with_panelist_and_associated_data(panelist_name) do
    (from cis in Interview,
      join: c in assoc(cis, :candidate),
      join: cs in assoc(c, :candidate_skills),
      join: i in assoc(cis, :interview_type),
      join: ip in assoc(cis, :interview_panelist),
      # TODO: Remove preload of master data (interview_type)
      preload: [:interview_type, candidate: {c, [candidate_skills: cs]}],
      where: ip.panelist_login_name == ^panelist_name,
      select: cis)
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_date_time(:start_time)
    |> unique_constraint(:interview_type_id, name: :candidate_interview_type_id_index)
    |> assoc_constraint(:candidate)
    |> assoc_constraint(:interview_type)
  end

  # TODO: Move this into a utility module that is imported?
  def validate_date_time(existing_changeset, field) do
    value = get_field(existing_changeset, field)
    cast_date_time = DateTime.cast(value)
    if cast_date_time == :error && value != "", do: add_error(existing_changeset, :"#{field}", "is invalid")
    existing_changeset
  end
end
