defmodule RecruitxBackend.RoleControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.RoleController

  describe "index" do
    let :roles do
      Enum.map([build(:role), build(:role)], fn(c) -> c |> Repo.preload(:role_skills) |>  Repo.preload(:role_interview_types) end)
    end

    before do: allow Repo |> to(accept(:all, fn(_) -> roles end))
    subject do: action :index

    it do: should be_successful
    it do: should have_http_status(:ok)

    it "should return the array of roles as a JSON response" do
      response = action(:index)

      expect(response.assigns.roles) |> to(eq(roles))
    end
  end
end
