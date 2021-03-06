defmodule RecruitxBackend.InterviewStatus do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.AppConstants
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Repo

  def pass, do: "Pass"
  def pursue, do: "Pursue"
  def strong_pursue, do: "Strong Pursue"

  schema "interview_status" do
    field :name, :string

    has_many :interviews, Interview

    timestamps()
  end

  @required_fields ~w(name)
  @optional_fields ~w()

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(Enum.map(@required_fields, &String.to_atom(&1)))
    |> validate_length(:name, min: 1, max: 255)
    |> validate_format(:name, AppConstants.name_format)
    |> unique_constraint(:name, name: :interview_status_name_index)
  end

  def retrieve_by_name(name), do: (from is in __MODULE__, where: is.name == ^name) |> Repo.one
end
