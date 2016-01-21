defmodule RecruitxBackend.SkillControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.SkillController

  describe "index" do
    let :skills do
      [
        build(:skill),
        build(:skill)
      ]
    end

    before do: allow Repo |> to(accept(:all, fn(_) -> skills end))
    subject do: action :index

    it do: should be_successful
    it do: should have_http_status(:ok)

    it "should return the array of skills as a JSON response" do
      response = action(:index)

      expect(response.resp_body) |> to(eq(Poison.encode!(skills, keys: :atoms!)))
    end
  end
end
