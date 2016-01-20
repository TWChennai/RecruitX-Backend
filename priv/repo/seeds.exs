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

import Ecto.Query

alias RecruitxBackend.Candidate
alias RecruitxBackend.Repo
alias RecruitxBackend.Role
alias RecruitxBackend.Skill
alias RecruitxBackend.Interview

Enum.map(["Dev",
          "QA",
          "BA",
          "PM",
          "UI/UX"], fn role_value ->
  Repo.insert!(%Role{name: role_value})
end)

Enum.map(["Java",
          "Ruby",
          "C#",
          "Python",
          "Other"], fn skill_value ->
  Repo.insert!(%Skill{name: skill_value})
end)

Enum.map(%{"Code Pairing" => 1,
           "Technical1" => 2,
           "Technical2" => 3,
           "Leadership" => 4,
           "P3" => 4}, fn {name_value, priority_value} ->
  Repo.insert!(%Interview{name: name_value, priority: priority_value})
end)

role_ids = Repo.all(from role in Role, select: role.id)
Enum.map(["Dinesh",
          "Kausalya",
          "Maha",
          "Navaneetha",
          "Pranjal",
          "Sivasubramanian",
          "Subha",
          "Vijay"], fn name_value ->
  Repo.insert!(%Candidate{name: name_value, experience: Decimal.new(Float.round(:random.uniform * 10, 2)), role_id: Enum.random(role_ids)})
end)
