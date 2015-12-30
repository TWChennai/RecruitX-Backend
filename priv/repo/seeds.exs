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

    find_by_name_or_create = fn modelName, model, data   ->
          case Repo.all(modelName.getByName(data.name)) do
           [] ->
                changeset = modelName.changeset(model, data)
                Repo.insert!(changeset)
           _ ->
                IO.puts " #{modelName} : #{data.name} already exists, skipping"
          end
    end

    find_by_name_or_create.(Role, %Role{}, %{name: "Dev"})
    find_by_name_or_create.(Role, %Role{}, %{name: "QA"})
    find_by_name_or_create.(Role, %Role{}, %{name: "BA"})
    find_by_name_or_create.(Role, %Role{}, %{name: "PM"})
    find_by_name_or_create.(Role, %Role{}, %{name: "UI/UX"})

    find_by_name_or_create.(Skill, %Skill{}, %{name: "Java"})
    find_by_name_or_create.(Skill, %Skill{}, %{name: "C#"})
    find_by_name_or_create.(Skill, %Skill{}, %{name: "Ruby"})
    find_by_name_or_create.(Skill, %Skill{}, %{name: "Python"})

    find_by_name_or_create.(Interview, %Interview{}, %{name: "Code Pairing", priority: 1})
    find_by_name_or_create.(Interview, %Interview{}, %{name: "Technical1", priority: 2})
    find_by_name_or_create.(Interview, %Interview{}, %{name: "Technical2", priority: 3})
    find_by_name_or_create.(Interview, %Interview{}, %{name: "Leadership", priority: 4})
    find_by_name_or_create.(Interview, %Interview{}, %{name: "P3", priority: 4})


