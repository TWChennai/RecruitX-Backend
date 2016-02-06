defmodule RecruitxBackend.InterviewControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.InterviewController

  describe "show" do
    let :interview, do: build(:interview, id: 1)
    before do: allow Repo |> to(accept(:get!, fn(Query, 1) -> interview end))

    subject do: action(:show, %{"id" => 1})

    it do: should be_successful
    it do: should have_http_status(:ok)
  end

  describe "index" do
    it "should report missing panelist_login_name param" do
      conn = action(:index, %{})
      conn |> should(have_http_status(400))
      expect(conn.assigns.param) |> to(eql("panelist_login_name"))
    end
  end
end
