defmodule RecruitxBackend.InterviewPanelist do
  use RecruitxBackend.Web, :model

  alias RecruitxBackend.CandidateInterviewSchedule
  alias RecruitxBackend.Panelist

  @derive {Poison.Encoder, only: [:id, :interview, :panelist]}
  schema "interview_panelist" do
    belongs_to :panelist, Panelist
    belongs_to :interview, CandidateInterviewSchedule

    timestamps
  end

  @required_fields ~w(panelist_id interview_id)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:interview_panelist_id, name: :interview_panelist_id_index)
    |> assoc_constraint(:panelist)
    |> assoc_constraint(:interview)
  end

end
