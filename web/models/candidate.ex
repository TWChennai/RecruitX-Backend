defmodule RecruitxBackend.Candidate do
    use RecruitxBackend.Web, :model

    alias RecruitxBackend.Role

    @derive {Poison.Encoder, only: [:name]}
    schema "candidates" do
        field :name, :string
        field :experience, :decimal
        field :addtional_information, :string

        belongs_to :role, Role
        timestamps
    end

    @required_fields ~w(name role_id experience)
    @optional_fields ~w()

    def changeset(model, params \\ :empty) do
        model
            |> cast(params, @required_fields, @optional_fields)
            |> validate_length(:name, min: 1)
            #|> foreign_key_constraint(:role_id)
    end
end
