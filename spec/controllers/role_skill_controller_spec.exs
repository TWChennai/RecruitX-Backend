defmodule RecruitxBackend.RoleSkillControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.RoleSkillController

  describe "index" do
    let :role_skills do
      [
        build(:role_skill),
        build(:role_skill),
      ]
    end

    before do: allow Repo |> to(accept(:all, fn(_) -> role_skills end))
    subject do: action :index

    it do: should be_successful
    it do: should have_http_status(:ok)

    it "should return the array of role_skills as a JSON response" do
      response = action(:index)

      expect(response.assigns.role_skills) |> to(eq(role_skills))
    end
  end
end
