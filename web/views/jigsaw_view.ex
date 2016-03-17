defmodule RecruitxBackend.JigsawView do
  use RecruitxBackend.Web, :view

  def render("show.json", %{user_details: user_details}) do
    %{
      is_recruiter: user_details.is_recruiter,
      calculated_hire_date: Timex.DateFormat.format!(user_details.calculated_hire_date, "%Y-%m-%d", :strftime),
      past_experience: user_details.past_experience
    }
  end
end
