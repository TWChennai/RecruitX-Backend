defmodule RecruitxBackend.InterviewType do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.Interview
  alias RecruitxBackend.Repo

  @panelists_for_leadership ["ppanelist", "vsiva", "sasikalm", "tchandra", "govinds"]

  @panelists_for_p3 ["ppanelistp", "vsingh", "pkundu", "prabirp", "siddadel", "srijays", "virapant"]

  schema "interview_types" do
    field :name, :string
    field :priority, :integer
    field :max_sign_up_limit, :integer

    timestamps

    has_many :interviews, Interview
  end

  @required_fields ~w(name max_sign_up_limit)
  @optional_fields ~w(priority)

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

  def default_order(query) do
    from i in query, order_by: [asc: i.priority, asc: i.id]
  end

  def get_sign_up_limits,
    do: (from it in __MODULE__, select: {it.id, it.max_sign_up_limit}) |> Repo.all

  def retrieve_by_name(name), do: (from it in __MODULE__, where: it.name == ^name) |> Repo.one
end
