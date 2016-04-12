defmodule RecruitxBackend.Candidate do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.AppConstants
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.InterviewStatus
  alias RecruitxBackend.Role
  alias RecruitxBackend.Repo
  alias Timex.Date

  schema "candidates" do
    field :first_name, :string
    field :last_name, :string
    field :experience, :decimal
    field :other_skills, :string
    field :pipeline_closure_time, Timex.Ecto.DateTime

    timestamps

    belongs_to :role, Role
    belongs_to :pipeline_status, PipelineStatus
    has_many :candidate_skills, CandidateSkill
    has_many :interviews, Interview
    has_many :skills, through: [:candidate_skills, :skill]
  end

  @required_fields ~w(first_name last_name experience role_id)
  @optional_fields ~w(other_skills pipeline_status_id pipeline_closure_time)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> add_default_pipeline_status
    |> validate_length(:first_name, min: 1)
    |> validate_format(:first_name, AppConstants.name_format)
    |> validate_length(:last_name, min: 1)
    |> validate_format(:last_name, AppConstants.name_format)
    |> validate_number(:experience, greater_than_or_equal_to: Decimal.new(0),less_than: Decimal.new(100), message: "must be in the range 0-100")
    |> assoc_constraint(:role)
    |> assoc_constraint(:pipeline_status)
    |> populate_pipeline_closure_time
  end

  defp populate_pipeline_closure_time(existing_changeset) do
    pipeline_status_id = existing_changeset |> get_field(:pipeline_status_id)
    if !is_nil(pipeline_status_id) do
      closed_pipeline_status_id = PipelineStatus.retrieve_by_name(PipelineStatus.closed).id
      if pipeline_status_id == closed_pipeline_status_id, do: existing_changeset = existing_changeset |> put_change(:pipeline_closure_time, Date.now())
    end
    existing_changeset
  end

  defp pipeline_closure_within_range(query, start_date, end_date) do
    from c in query, where: c.pipeline_closure_time >= ^start_date and c.pipeline_closure_time <= ^end_date
  end

  def get_candidates_pursued_and_rejected_after_pipeline_closure_separately(%{starting: start_date, ending: end_date}) do
    pipeline_closed_candidates = __MODULE__
                                  |> pipeline_closure_within_range(start_date, end_date)
                                  |> Repo.all

    pursue_interview_status_id = (InterviewStatus.pursue |> InterviewStatus.retrieve_by_name).id
    strong_pursue_interview_status_id = (InterviewStatus.strong_pursue |> InterviewStatus.retrieve_by_name).id
    last_interviews_data = Interview.get_candidates_with_all_rounds_completed |> Repo.all

    Enum.partition(
      pipeline_closed_candidates, fn(candidate) ->
        status = Interview.get_last_interview_status_for(candidate, last_interviews_data)
        status == strong_pursue_interview_status_id || status == pursue_interview_status_id
      end)
  end

  def get_no_of_pass_candidates_within_range(%{starting: start_date, ending: end_date}) do
    pass_status_id = (PipelineStatus.retrieve_by_name(PipelineStatus.pass)).id
    candidates_passed = (from c in __MODULE__, where: c.pipeline_status_id == ^pass_status_id) |> Repo.all
    last_interviews_data = Interview.get_candidates_with_all_rounds_completed |> Repo.all

    Enum.count(candidates_passed, fn(candidate) ->
      Enum.any?(last_interviews_data, fn (last_interview)->
        [candidate_id, max_start_time, _] = last_interview
        pass_interview_start_time = Date.from(max_start_time)
        candidate_id == candidate.id &&
        pass_interview_start_time >= start_date  &&
        pass_interview_start_time <= end_date
      end)
    end)
  end

  def get_candidate_by_id(id) do
    from c in __MODULE__,
    where: c.id == ^id,
    preload: [:role, interviews: ^Interview.get_interviews_ordered_by_start_time]
  end

  defp add_default_pipeline_status(existing_changeset) do
    incoming_id = existing_changeset |> get_field(:pipeline_status_id)
    if is_nil(incoming_id) do
      in_progess_id = PipelineStatus.retrieve_by_name(PipelineStatus.in_progress).id
      existing_changeset = existing_changeset |> put_change(:pipeline_status_id, in_progess_id)
    end
    existing_changeset
  end

  def updateCandidateStatusAsPass(id) do
    candidate = __MODULE__ |> Repo.get(id)
    pass_pipeline_status_id = PipelineStatus.retrieve_by_name(PipelineStatus.pass).id
    candidate_params = %{
      "pipeline_status_id": pass_pipeline_status_id
    }
    __MODULE__.changeset(candidate, candidate_params) |> Repo.update
  end

  def get_candidates_in_fifo_order do
    interview_type_id_with_min_priority = InterviewType.get_ids_of_min_priority_round
    from c in __MODULE__,
      left_join: i in assoc(c, :interviews),
      where: i.interview_type_id in ^interview_type_id_with_min_priority or is_nil(i.interview_type_id),
      order_by: i.start_time,
      select: c
  end

  def is_pipeline_closed(candidate) do
    closed_id = PipelineStatus.retrieve_by_name(PipelineStatus.closed).id
    candidate.pipeline_status_id == closed_id
  end

  def get_formatted_skills(candidate) do
    (Enum.reduce(candidate.skills, "", fn(skill, accumulator) ->
      skill_name = skill.name
      if skill_name == "Other", do: skill_name = candidate.other_skills
      accumulator <> ", " <> skill_name
    end))
    |> String.lstrip(?,)
    |> String.lstrip
  end

  def get_formatted_interviews(candidate) do
    Enum.map(candidate.interviews, &(Interview.format(&1)))
  end

  def get_total_no_of_candidates_in_progress do
    (from c in __MODULE__,
    join: p in assoc(c, :pipeline_status),
    where: p.name == ^PipelineStatus.in_progress,
    select: count(c.id))
      |> Repo.one
  end

  def get_formatted_interviews_with_result(candidate) do
    Enum.map(candidate.interviews, &(Interview.format_with_result_and_panelist(&1)))
  end

  def get_rounded_experience(candidate) do
    experience_as_string = Decimal.to_string(candidate.experience)
    experience_as_float = String.to_float(experience_as_string)
    Float.to_string(experience_as_float, decimals: 1)
  end
end
