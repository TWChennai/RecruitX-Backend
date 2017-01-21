defmodule RecruitxBackend.SlotView do
  use RecruitxBackend.Web, :view

  alias RecruitxBackend.TimexHelper

  def render("index.json", %{slots: slots}) do
    render_many(slots, __MODULE__, "show.json")
  end

  def render("show.json", %{slot: slot}) do
    %{
      id: slot.id,
      role_id: slot.role_id,
      interview_type_id: slot.interview_type_id,
      start_time: TimexHelper.format(slot.start_time, "%Y-%m-%dT%H:%M:%SZ"),
      skills: slot.skills,
      experience: slot.average_experience
    }
  end
end
