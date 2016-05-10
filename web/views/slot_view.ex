defmodule RecruitxBackend.SlotView do
  use RecruitxBackend.Web, :view

  def render("show.json", %{slot: slot}) do
    %{
      role_id: slot.role_id,
      interview_type_id: slot.interview_type_id,
      start_time: slot.start_time
    }
  end
end
