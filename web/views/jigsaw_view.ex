defmodule RecruitxBackend.JigsawView do
  use RecruitxBackend.Web, :view

  def render("show.json", %{user_details: user_details}) do
    %{
      is_recruiter: user_details.is_recruiter,
      tw_hire_date: user_details.tw_hire_date,
      past_experience: user_details.past_experience
    }
  end
end
