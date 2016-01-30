defmodule RecruitxBackend.Factory do
  use ExMachina.Ecto, repo: RecruitxBackend.Repo

  alias RecruitxBackend.Repo
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Role
  alias RecruitxBackend.Skill
  alias RecruitxBackend.CandidateInterviewSchedule
  alias Ecto.DateTime
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
    skill_ids = Repo.all(from s in Skill, select: s.id) |> Enum.shuffle
    %{skill_ids: skill_ids}
  end

  def factory(:interview_rounds) do
    current_interview_count = Ectoo.count(Repo, Interview)
    interview_rounds = for n <- 1..:rand.uniform(current_interview_count) do
      %{"interview_id" => n, "interview_date_time" => getRandomDateTimeString}
    end
    %{interview_rounds: interview_rounds}
  end

  def factory(:interview) do
    %Interview{
      name: Faker.Name.first_name,   # TODO: Find a way to specify from a list of known langugages
    }
  end

  def factory(:candidate_interview_schedule) do
    candidate = create(:candidate)
    interview = create(:interview)
    %CandidateInterviewSchedule{
      candidate_interview_date_time: getRandomDateTimeString,
      candidate: candidate,
      candidate_id: candidate.id,
      interview: interview,
      interview_id: interview.id,
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
      skill: skill,
      skill_id: skill.id
    }
  end

  def getRandomDateTimeString do
    DateTime.cast!(DateTime.utc |> DateTime.to_string)
  end
end
