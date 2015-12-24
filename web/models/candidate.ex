defmodule RecruitxBackend.Candidate do
    use RecruitxBackend.Web, :model

    alias RecruitxBackend.Repo
    alias RecruitxBackend.Candidate

    @derive {Poison.Encoder, only: [:name]}
    schema "candidates" do
        field :name, :string
        timestamps
    end

    @required_fields ~w(name)
    @optional_fields ~w()

    def changeset(model, params \\ :empty) do
        model
            |> cast(params, @required_fields, @optional_fields)
            |> validate_length(:name, min: 1)
    end
end
