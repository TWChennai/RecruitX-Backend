defmodule RecruitxBackend.FeedbackImageView do
  use RecruitxBackend.Web, :view

  def render("feedback_image.json", %{feedback_image: feedback_image}) do
    %{
      file_name: feedback_image.file_name
    }
  end
end
