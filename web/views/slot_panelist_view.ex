defmodule RecruitxBackend.SlotPanelistView do
  use RecruitxBackend.Web, :view

  def render("show.json", %{slot_panelist: slot_panelist}) do
    %{data: render_one(slot_panelist, RecruitxBackend.SlotPanelistView, "slot_panelist.json")}
  end

  def render("slot_panelist.json", %{slot_panelist: slot_panelist}) do
    %{id: slot_panelist.id}
  end
end
