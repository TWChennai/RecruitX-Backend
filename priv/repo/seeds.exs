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
alias RecruitxBackend.Skill

    Repo.insert!(%Skill{name: "Java"})
    Repo.insert!(%Skill{name: "Ruby"})
    Repo.insert!(%Skill{name: "C#"})
    Repo.insert!(%Skill{name: "Python"})