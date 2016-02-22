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
alias RecruitxBackend.Repo
alias RecruitxBackend.Role
alias RecruitxBackend.Skill
alias RecruitxBackend.PipelineStatus

# NOTE: Non-transactional data should never be in this file - only as part of migrations.
roles = Repo.all(Role)
skills = Repo.all(Skill)
pipeline_statuses = Repo.all(PipelineStatus)

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
  Repo.insert!(%Candidate{first_name: first_name, last_name: last_name, experience: Decimal.new(Float.round(:rand.uniform * 10, 2)), other_skills: other_skills, role_id: Enum.random(roles).id, pipeline_status_id: Enum.random(pipeline_statuses).id})
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

panelist_names = ["dineshb", "kausalym", "mahalaks", "navaneth", "pranjald", "vsiva", "subham", "vraravam"]
Enum.each(candidates, fn candidate ->
  now = Timex.Date.now
  for interview_round_number <- 1..:rand.uniform(5) do
    interview = Repo.insert!(%Interview{candidate_id: candidate.id, interview_type_id: interview_round_number, start_time: now |> Timex.Date.shift(hours: interview_round_number)})
    for _ <- 1..:rand.uniform(2) do
        try do
          Repo.insert!(%InterviewPanelist{interview_id: interview.id, panelist_login_name: Enum.random(panelist_names)})
        rescue
          ConstraintError -> {} # ignore the unique constraint violation errors
        end
    end
  end
end)
