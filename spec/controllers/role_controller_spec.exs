defmodule RecruitxBackend.RoleControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.RoleController

  alias RecruitxBackend.Role

  describe "index" do
    let :roles do
      [
        %Role{id: 1, name: "Dev"},
        %Role{id: 2, name: "QA"},
      ]
    end

    before do: allow Repo |> to(accept(:all, fn(_) -> roles end))
    subject do: action :index

    it do: should be_successful
    it do: should have_http_status(:ok)
    it "should return the array of roles as a JSON response" do
      response = action(:index)

      expect(response.resp_body) |> to(eq(Poison.encode!(roles, keys: :atoms!)))
    end
  end
end
