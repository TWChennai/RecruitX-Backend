defmodule RecruitxBackend.JigsawView do
  use RecruitxBackend.Web, :view

 def render("show.json", %{is_recruiter: is_recruiter}) do
   %{
     is_recruiter: is_recruiter
   }
  end

end
