defmodule RecruitxBackend.InterviewTypeControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.InterviewTypeController

  describe "index" do
    let :interview_types do
      [
        build(:interview_type),
        build(:interview_type)
      ]
    end

    before do: allow Repo |> to(accept(:all, fn(_) -> interview_types end))
    subject do: action :index

    it do: should be_successful
    it do: should have_http_status(:ok)

    it "should return the array of interview_types as a JSON response" do
      response = action(:index)

      expect(response.resp_body) |> to(eq(Poison.encode!(interview_types, keys: :atoms!)))
    end
  end
end
