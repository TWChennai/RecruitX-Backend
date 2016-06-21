defmodule RecruitxBackend.LoginControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.LoginController

  it "should redirect to the okta url provided" do
    response = action(:index, %{})
    response |> should(have_http_status(200))
  end
end
