defmodule RecruitxBackend.Interview do
  use RecruitxBackend.Web, :model

  alias Timex.Date
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.FeedbackImage
  alias RecruitxBackend.Repo

  import RecruitxBackend.CustomValidators

  schema "interviews" do
    field :start_time, Timex.Ecto.DateTime
    belongs_to :candidate, Candidate
    belongs_to :interview_type, InterviewType

    timestamps

    has_many :interview_panelist, InterviewPanelist
    has_many :feedback_image, FeedbackImage
  end

  @required_fields ~w(candidate_id interview_type_id start_time)
  @optional_fields ~w()

  def now_or_in_next_seven_days(query) do
    start_of_today = Date.set(Date.now, time: {0,0,0})
    from i in query, where: i.start_time >= ^start_of_today and i.start_time <= ^(start_of_today |> Date.shift(days: 7))
  end

  def default_order(query) do
    from i in query, order_by: [asc: i.start_time, asc: i.id]
  end

  def get_candidate_ids_interviewed_by(panelist_login_name) do
    from ip in InterviewPanelist,
      where: ip.panelist_login_name == ^panelist_login_name,
      join: i in assoc(ip, :interview),
      group_by: i.candidate_id,
      select: i.candidate_id
  end

  def get_interviews_with_associated_data do
    (from i in Interview,
      join: c in assoc(i, :candidate),
      join: cs in assoc(c, :candidate_skills),
      preload: [candidate: {c, [candidate_skills: cs]}],
      select: i) |> default_order
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    # TODO: Shouldn't the start_time only be in the future if the record is being created for the first time?
    |> validate_date_time(:start_time)
    |> unique_constraint(:interview_type_id, name: :candidate_interview_type_id_index)
    |> assoc_constraint(:candidate)
    |> assoc_constraint(:interview_type)
  end

  # TODO: Should this be added as a validation?
  def signup(model, candidate_ids_interviewed) do
    # TODO: Move the magic number (2) into the db
    has_panelist_not_interviewed_candidate(model, candidate_ids_interviewed) and is_signup_lesser_than(model.id, 2)
  end

  def has_panelist_not_interviewed_candidate(model, candidate_ids_interviewed) do
    !Enum.member?(candidate_ids_interviewed, model.candidate_id)
  end

  def is_signup_lesser_than(model_id, max_count) do
    signup_counts = InterviewPanelist.get_interview_type_based_count_of_sign_ups |> Repo.all
    result = Enum.filter(signup_counts, fn(i) -> i.interview_id == model_id end)
    result == [] or List.first(result).signup_count < max_count
  end
end
