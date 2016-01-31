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

alias Ecto.DateTime
alias Ecto.ConstraintError
alias RecruitxBackend.Candidate
alias RecruitxBackend.CandidateInterviewSchedule
alias RecruitxBackend.CandidateSkill
alias RecruitxBackend.InterviewType
alias RecruitxBackend.Repo
alias RecruitxBackend.Role
alias RecruitxBackend.Skill

roles = Enum.map(["Dev",
          "QA",
          "BA",
          "PM",
          "UI/UX"], fn role_value ->
  Repo.insert!(%Role{name: role_value})
end)

skills = Enum.map(["Java",
          "Ruby",
          "C#",
          "Python",
          "Other"], fn skill_value ->
  Repo.insert!(%Skill{name: skill_value})
end)

interview_types = Enum.map(%{"Code Pairing1" => 1,
           "Technical11" => 2,
           "Technical21" => 3,
           "Leadersh1ip" => 4,
           "P13" => 4}, fn {name_value, priority_value} ->
  Repo.insert!(%InterviewType{name: name_value, priority: priority_value})
end)

candidates = Enum.map(%{"Dinesh" => "Hadoop",
          "Kausalya" => "Hbase",
          "Maha" => "IOT",
          "Navaneetha" => "Hadoop, IOT",
          "Pranjal" => "Elixir",
          "Sivasubramanian" => "AngularJS",
          "Subha" => "NodeJS",
          "Vijay" => "Haskell"}, fn {name_value, additional_information_value} ->
  Repo.insert!(%Candidate{name: name_value, experience: Decimal.new(Float.round(:rand.uniform * 10, 2)), additional_information: additional_information_value, role_id: Enum.random(roles).id})
end)

Enum.each(candidates, fn candidate ->
  for _ <- 1..:rand.uniform(2) do
    try do
      Repo.insert!(%CandidateSkill{candidate_id: candidate.id, skill_id: Enum.random(skills).id})
    rescue
      ConstraintError -> {} # ignore the unique constraint violation errors
    end
  end
end)

Enum.each(candidates, fn candidate ->
  for _ <- 1..:rand.uniform(2) do
    try do
      Repo.insert!(%CandidateInterviewSchedule{candidate_id: candidate.id, interview_type_id: Enum.random(interview_types).id, candidate_interview_date_time: DateTime.utc})
    rescue
      ConstraintError -> {} # ignore the unique constraint violation errors
    end
  end
end)
