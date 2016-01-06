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
          "Python"], fn skill_value ->
  Repo.insert!(%Skill{name: skill_value})
end)

Enum.map(%{"Code Pairing" => 1,
            "Technical1" => 2,
            "Technical2" => 3,
            "Leadership" => 4,
            "P3" => 4}, fn {name_value, priority_value} ->
  Repo.insert!(%Interview{name: name_value, priority: priority_value})
end)
