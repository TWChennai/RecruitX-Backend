defmodule RecruitxBackend.Factory do
  use ExMachina.Ecto, repo: RecruitxBackend.Repo

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.InterviewStatus
  alias RecruitxBackend.FeedbackImage
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Role
  alias RecruitxBackend.Skill
  alias Timex.Date
  alias Timex.DateFormat
  alias Timex.Ecto.DateTime

  import Ecto.Query

  def factory(:role) do
    %Role{
      name: "#{Faker.Name.first_name} #{Faker.Name.last_name}"
    }
  end

  def factory(:skill) do
    %Skill{
      name: Faker.Name.first_name   # TODO: Find a way to specify from a list of known langugages
    }
  end

  def factory(:skill_ids) do
    create(:skill)
    skill_ids = Repo.all(from s in Skill, select: s.id) |> Enum.shuffle
    %{skill_ids: skill_ids}
  end

  def factory(:interview_rounds) do
    current_interview_count = Ectoo.count(Repo, InterviewType)
    create(:interview_type, id: current_interview_count + 1)
    create(:interview_type, id: current_interview_count + 2)
    interview_rounds = for n <- 1..:rand.uniform(2) do
      %{"interview_type_id" => current_interview_count + n, "start_time" => getRandomDateTimeString}
    end
    %{interview_rounds: interview_rounds}
  end

  def factory(:interview_type) do
    %InterviewType{
      name: Faker.Name.first_name,   # TODO: Find a way to specify from a list of known langugages
    }
  end

  def factory(:interview) do
    candidate = create(:candidate)
    interview_type = create(:interview_type)
    %Interview{
      start_time: getRandomDateTimeString,
      candidate: candidate,
      candidate_id: candidate.id,
      interview_type: interview_type,
      interview_type_id: interview_type.id,
    }
  end

  def factory(:candidate) do
    role = create(:role)
    %Candidate{
      name: Faker.Name.first_name,   # TODO: Find a way to specify from a list of known langugages
      experience: Decimal.new(Float.round(:rand.uniform * 10, 2)),
      role: role,
      role_id: role.id
    }
  end

  def factory(:candidate_skill) do
    candidate = create(:candidate)
    skill = create(:skill)
    %CandidateSkill{
      candidate: candidate,
      candidate_id: candidate.id,
      skill_id: skill.id
    }
  end

  def factory(:interview_panelist) do
    %InterviewPanelist{
      panelist_login_name: Faker.Name.first_name,
      interview_id: create(:interview).id
    }
  end

  def factory(:interview_status) do
    %InterviewStatus{
      name: "#{Faker.Name.first_name}"
    }
  end

  def factory(:feedback_image) do
    %FeedbackImage{
      file_name: "#{Faker.Name.first_name}",
      interview_id: create(:interview).id
    }
  end

  def getRandomDateTimeString do
    {_, value} = DateTime.cast(DateFormat.format!(Date.now, "%Y-%m-%d %H:%M:%S", :strftime))
    value
  end
end
