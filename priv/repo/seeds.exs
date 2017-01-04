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
alias RecruitxBackend.CandidateSkill
alias RecruitxBackend.Interview
alias RecruitxBackend.InterviewPanelist
alias RecruitxBackend.InterviewType
alias RecruitxBackend.PipelineStatus
alias RecruitxBackend.Repo
alias RecruitxBackend.Role
alias RecruitxBackend.Skill
alias RecruitxBackend.Slot
alias RecruitxBackend.SlotPanelist
alias RecruitxBackend.TimexHelper

import Ecto.Query, only: [from: 2]

# NOTE: Non-transactional data should never be in this file - only as part of migrations.
roles = Repo.all(from r in Role, where: r.name != ^Role.other)
skills = Repo.all(Skill)
in_progress = PipelineStatus.retrieve_by_name(PipelineStatus.in_progress)

candidates = Enum.map(%{"Dinesh B" => "Hadoop",
          "Kausalya M" => "Hbase",
          "Maha S" => "IOT",
          "Navaneetha K" => "Hadoop, IOT",
          "Pranjal D" => "Elixir",
          "Sivasubramanian V" => "AngularJS",
          "Arunvel Sriram" => "AngularJS",
          "Siva V" => "Go",
          "Subha M" => "NodeJS",
          "Vijay A" => "Haskell"}, fn {name_value, other_skills} ->
  [first_name, last_name] = String.split(name_value, " ")
  Repo.insert!(%Candidate{first_name: first_name, last_name: last_name, experience: Decimal.new(Float.round(Enum.random(20..50)/Enum.random(1..7), 2)), other_skills: other_skills, role: Enum.random(roles), pipeline_status: in_progress})
end)

Enum.each(candidates, fn candidate ->
  for _ <- 1..Enum.random(1..5) do
    try do
      Repo.insert!(%CandidateSkill{candidate: candidate, skill: Enum.random(skills)})
    rescue
      ConstraintError -> {} # ignore the unique constraint violation errors
    end
  end
end)

panelist_names = ["dineshb", "kausalym", "mahalaks", "navaneth", "pranjald", "vsiva", "subham", "vraravam"]

for interview_round_number <- 1..Enum.random(1..4) do
  now = TimexHelper.utc_now()
  random_start_time = now |> TimexHelper.add(interview_round_number, :hours)
  random_end_time = random_start_time |> TimexHelper.add(1, :hours)
  interview_type = (from it in InterviewType, where: it.priority == ^interview_round_number, limit: 1) |> Repo.one

  slot = Repo.insert!(%Slot{
    role: Enum.random(roles),
    start_time: random_start_time,
    end_time: random_end_time,
    average_experience: Decimal.new(Enum.random(1..10)),
    interview_type: interview_type,
  })
  Repo.insert!(%SlotPanelist{
    panelist_login_name: Enum.random(panelist_names),
    slot: slot
  })
end

Enum.each(candidates, fn candidate ->
  now = TimexHelper.utc_now()
  for interview_round_number <- 1..Enum.random(1..4) do
    random_start_time = now |> TimexHelper.add(interview_round_number, :hours)
    random_end_time = random_start_time |> TimexHelper.add(2, :hours)
    interview_type = (from it in InterviewType, where: it.priority == ^interview_round_number, limit: 1) |> Repo.one
    interview = Repo.insert!(%Interview{candidate: candidate, interview_type: interview_type, start_time: random_start_time, end_time: random_end_time})
    for _ <- 1..Enum.random(1..2) do
        try do
          Repo.insert!(%InterviewPanelist{interview: interview, panelist_login_name: Enum.random(panelist_names)})
        rescue
          ConstraintError -> {} # ignore the unique constraint violation errors
        end
    end
  end
end)
