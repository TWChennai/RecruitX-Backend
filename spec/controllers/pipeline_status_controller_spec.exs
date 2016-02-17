defmodule RecruitxBackend.PipelineStatusControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.PipelineStatusController

  describe "index" do
    let :pipeline_statuses do
      [
        build(:pipeline_status),
        build(:pipeline_status),
      ]
    end

    before do: allow Repo |> to(accept(:all, fn(_) -> pipeline_statuses end))
    subject do: action :index

    it do: should be_successful
    it do: should have_http_status(:ok)

    it "should return the array of pipeline_statuses as a JSON response" do
      response = action(:index)

      expect(response.assigns.pipeline_statuses) |> to(eq(pipeline_statuses))
    end
  end
end
