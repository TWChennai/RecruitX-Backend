defmodule RecruitxBackend.InterviewType do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Interview
  alias RecruitxBackend.Repo

  @panelists_for_leadership ["ppanelistp"]

  @panelists_for_p3 ["ppanelistp"]

  schema "interview_types" do
    field :name, :string
    field :priority, :integer

    timestamps

    has_many :interviews, Interview
  end

  @required_fields ~w(name)
  @optional_fields ~w(priority)

  def default_order(query) do
    from i in query, order_by: [asc: i.priority, asc: i.id]
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:name, min: 1, max: 255)
    |> validate_format(:name, ~r/^[a-z]+[\sa-z0-9]*$/i)
    |> unique_constraint(:name, name: :interview_types_name_index)
  end

  def telephonic, do: "TP"
  def coding, do: "Coding"
  def technical_1, do: "Tech-1"
  def technical_2, do: "Tech-2"
  def leadership, do: "Ldrshp"
  def p3, do: "P3"

  def get_type_specific_panelists do
    %{
      (retrieve_by_name(__MODULE__.leadership)).id => @panelists_for_leadership,
      (retrieve_by_name(__MODULE__.p3)).id => @panelists_for_p3
    }
  end

  def get_ids_of_min_priority_round do
    (from it in __MODULE__,
      select: it.id,
      where: fragment("? = (select it.priority from interview_types it order by it.priority limit 1)", it.priority))
      |> Repo.all
  end

  def retrieve_by_name(name),
  do: (from it in __MODULE__, where: it.name == ^name) |> Repo.one
end
