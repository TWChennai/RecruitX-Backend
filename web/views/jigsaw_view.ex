defmodule RecruitxBackend.JigsawView do
  use RecruitxBackend.Web, :view

  alias RecruitxBackend.RoleView
  alias RecruitxBackend.TimexHelper

  def render("show.json", %{user_details: user_details}) do
    %{
      is_recruiter: user_details.is_recruiter,
      calculated_hire_date: TimexHelper.format(user_details.calculated_hire_date, "%Y-%m-%d"),
      past_experience: user_details.past_experience,
      role: render_one(user_details.role, RoleView, "role_without_skills.json"),
      is_super_user: user_details.is_super_user,
      is_signup_cop: user_details.is_signup_cop,
      error: user_details.error
    }
  end
end
