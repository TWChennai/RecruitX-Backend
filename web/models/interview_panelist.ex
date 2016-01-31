defmodule RecruitxBackend.InterviewPanelist do
  use RecruitxBackend.Web, :model

  @derive {Poison.Encoder, only: [:id, :interview_id, :panelist_id]}
  schema "interview_panelist" do
    belongs_to :panelists, Panelists
    belongs_to :interview, CandidateInterviewSchedule

    timestamps
  end

  @required_fields ~w(panelist_id interview_id)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:interview_panelist_id, name: :interview_panelist_id_index)
    |> assoc_constraint(:panelists)
    |> assoc_constraint(:interview)
  end
  
end
