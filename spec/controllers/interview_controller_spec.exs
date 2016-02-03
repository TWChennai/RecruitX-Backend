defmodule RecruitxBackend.InterviewControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.InterviewController

  import Ecto.Query
  alias RecruitxBackend.Interview

  describe "show" do
    let :interview, do: build(:interview, id: 1)
    before do: allow Repo |> to(accept(:get!, fn(Query, 1) -> interview end))

    subject do: action(:show, %{"id" => 1})

    it do: should be_successful
    it do: should have_http_status(:ok)
  end
end
