defmodule RecruitxBackend.WeekendDriveView do
  use RecruitxBackend.Web, :view
  alias Timex.DateFormat

  def render("index.json", %{weekend_drives: weekend_drives}) do
    %{data: render_many(weekend_drives, RecruitxBackend.WeekendDriveView, "weekend_drive.json")}
  end

  def render("show.json", %{weekend_drive: weekend_drive}) do
     render_one(weekend_drive, RecruitxBackend.WeekendDriveView, "weekend_drive.json")
  end

  def render("weekend_drive.json", %{weekend_drive: weekend_drive}) do
    %{id: weekend_drive.id,
      role_id: weekend_drive.role_id,
      start_date: DateFormat.format!(weekend_drive.start_date, "%Y-%m-%dT%H:%M:%SZ", :strftime),
      end_date: DateFormat.format!(weekend_drive.end_date, "%Y-%m-%dT%H:%M:%SZ", :strftime),
      no_of_candidates: weekend_drive.no_of_candidates,
      no_of_panelists: weekend_drive.no_of_panelists}
  end
end
