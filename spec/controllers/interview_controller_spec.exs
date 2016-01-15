defmodule RecruitxBackend.InterviewControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.InterviewController

  import RecruitxBackend.Factory

  alias RecruitxBackend.Interview

  describe "index" do
    let :interviews do
      [
        build(:interview),
        build(:interview)
      ]
    end

    before do: allow Repo |> to(accept(:all, fn(_) -> interviews end))
    subject do: action :index

    it do: should be_successful
    it do: should have_http_status(:ok)

    it "should return the array of interviews as a JSON response" do
      response = action(:index)

      expect(response.resp_body) |> to(eq(Poison.encode!(interviews, keys: :atoms!)))
    end
  end
end
