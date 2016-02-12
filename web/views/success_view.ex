defmodule RecruitxBackend.SuccessView do
  use RecruitxBackend.Web, :view

  def render("success.json", %{message: message}) do
    %{success: message}
  end
end
