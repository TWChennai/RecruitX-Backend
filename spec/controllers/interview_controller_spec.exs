defmodule RecruitxBackend.InterviewControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.InterviewController

  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewView
  alias RecruitxBackend.Repo

  before do: Repo.delete_all(Interview)

  describe "show" do
    let :interview, do: create(:interview, id: 1)
    before do: allow Repo |> to(accept(:get, fn(_, 1) -> interview end))
    before do: allow InterviewView |> to(accept(:render, fn("show.json", _) -> nil end))

    subject do: action(:show, %{"id" => 1})

    it do: should be_successful
    it do: should have_http_status(:ok)
  end

  describe "index" do
    it "should report missing panelist_login_name param" do
      conn = action(:index, %{})
      conn |> should(have_http_status(400))
      expect(conn.assigns.param) |> to(eql("panelist_login_name/candidate_id/panelist_name/panelist_experience/panelist_role"))
    end
  end

  describe "update" do
    let :updated_interview, do: create(:interview)

    describe "valid params" do
      before do: allow Repo |> to(accept(:update, fn(_) -> {:ok, updated_interview} end))

      it "should return status ok and be successful" do
        conn = action(:update, %{"id" => updated_interview.id, "interview" => %{"start_time" => "1992-02-11 10:00:05" }})

        conn |> should(be_successful)
        conn |> should(have_http_status(:ok))
      end
    end

    describe "invalid params" do
      before do: allow Repo |> to(accept(:update, fn(changeset) -> {:error, changeset} end))

      it "should not be successful" do
        conn = action(:update, %{"id" => updated_interview.id, "interview" => %{"start_time" => "" }})

        conn |> should_not(be_successful)
        conn |> should(have_http_status(:unprocessable_entity))
      end
    end
  end
end
