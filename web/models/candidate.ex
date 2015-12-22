defmodule RecruitxBackend.Candidate do
    use RecruitxBackend.Web, :model

    alias RecruitxBackend.Repo
    alias RecruitxBackend.Candidate

    schema "candidates" do
        field :name, :string
        timestamps
    end

    @required_fields ~w(name)
    @optional_fields ~w()

    def all do
        to_json(Repo.all(Candidate))
    end

    def to_json(candidate) do
        Poison.encode!(candidate)
    end

    def insert(candidate_params) do
        changeset = Candidate.changeset(%Candidate{}, candidate_params)
        if(changeset.valid?) do
            Repo.insert(changeset)
        end
    end

    def changeset(model, params \\ :empty) do
        model
            |> cast(params, @required_fields, @optional_fields)
            |> validate_length(:name, min: 1)
    end
end

defimpl Poison.Encoder, for: RecruitxBackend.Candidate do
  def encode(candidate, _options) do
    %{
      name: candidate.name
    } |> Poison.Encoder.encode([])
  end
end
