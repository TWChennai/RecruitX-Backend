defmodule RecruitxBackend.InterviewStatusControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.InterviewStatusController

  describe "index" do
    let :interview_status do
      [
        build(:interview_status),
        build(:interview_status)
      ]
    end

    before do: allow Repo |> to(accept(:all, fn(_) -> interview_status end))
    subject do: action :index

    it do: should be_successful
    it do: should have_http_status(:ok)

    it "should return the array of interview status as a JSON response" do
      response = action(:index)

      expect(response.assigns.interview_status) |> to(eq(interview_status))
    end
  end
end
