# TODO: For associations, should we do 'build', or 'create' or do the association using the 'fk_id'?
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
    current_skill_count = Ectoo.count(Repo, Skill)
    skill_ids = for n <- 1..:rand.uniform(current_skill_count), do: :rand.uniform(current_skill_count)
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
    %CandidateInterviewSchedule{
      candidate_interview_date_time: getRandomDateTimeString,
      candidate_id: create(:candidate).id,
      interview_id: create(:interview).id
    }
  end

  def factory(:candidate) do
    %Candidate{
      name: Faker.Name.first_name,   # TODO: Find a way to specify from a list of known langugages
      experience: Decimal.new(Float.round(:rand.uniform * 10, 2)),
      role: create(:role)
    }
  end

  def factory(:candidate_skill) do
    %CandidateSkill{
      candidate: build(:candidate),
      skill: build(:skill),
    }
  end

  def getRandomDateTimeString do
    DateTime.cast!(DateTime.utc |> DateTime.to_string)
  end
end
