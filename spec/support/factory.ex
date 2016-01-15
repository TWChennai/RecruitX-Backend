defmodule RecruitxBackend.Factory do
  use ExMachina.Ecto, repo: RecruitxBackend.Repo

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Role
  alias RecruitxBackend.Skill

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

  def factory(:interview) do
    %Interview{
      name: Faker.Name.first_name,   # TODO: Find a way to specify from a list of known langugages
    }
  end

  def factory(:candidate) do
    %Candidate{
      name: Faker.Name.first_name,   # TODO: Find a way to specify from a list of known langugages
      experience: Decimal.new(Float.round(:random.uniform * 10, 2)),
      role: build(:role)
    }
  end

  def factory(:candidate_skill) do
    %CandidateSkill{
      candidate: build(:candidate),
      skill: build(:skill),
    }
  end
end
