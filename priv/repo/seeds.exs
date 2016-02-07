# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     RecruitxBackend.Repo.insert!(%SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Ecto.ConstraintError
alias RecruitxBackend.Candidate
alias RecruitxBackend.Interview
alias RecruitxBackend.CandidateSkill
alias RecruitxBackend.InterviewType
alias RecruitxBackend.Repo
alias RecruitxBackend.Role
alias RecruitxBackend.Skill

# NOTE: Non-transactional data should never be in this file - only as part of migrations.
roles = Repo.all(Role)
skills = Repo.all(Skill)
interview_types = Repo.all(InterviewType)

candidates = Enum.map(%{"Dinesh" => "Hadoop",
          "Kausalya" => "Hbase",
          "Maha" => "IOT",
          "Navaneetha" => "Hadoop, IOT",
          "Pranjal" => "Elixir",
          "Sivasubramanian" => "AngularJS",
          "Subha" => "NodeJS",
          "Vijay" => "Haskell"}, fn {name_value, other_skills} ->
  Repo.insert!(%Candidate{name: name_value, experience: Decimal.new(Float.round(:rand.uniform * 10, 2)), other_skills: other_skills, role_id: Enum.random(roles).id})
end)

Enum.each(candidates, fn candidate ->
  for _ <- 1..:rand.uniform(5) do
    try do
      Repo.insert!(%CandidateSkill{candidate_id: candidate.id, skill_id: Enum.random(skills).id})
    rescue
      ConstraintError -> {} # ignore the unique constraint violation errors
    end
  end
end)

Enum.each(candidates, fn candidate ->
  now = Timex.Date.now
  for _ <- 1..:rand.uniform(5) do
    multiplier = if :rand.uniform(2) == 2, do: 1, else: -1
    try do
      Repo.insert!(%Interview{candidate_id: candidate.id, interview_type_id: Enum.random(interview_types).id, start_time: now |> Timex.Date.shift(days: (multiplier * :rand.uniform(10)))})
    rescue
      ConstraintError -> {} # ignore the unique constraint violation errors
    end
  end
end)
