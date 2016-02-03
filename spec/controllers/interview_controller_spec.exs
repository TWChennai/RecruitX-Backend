defmodule RecruitxBackend.InterviewControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.InterviewController

  alias RecruitxBackend.InterviewController

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
      conn |> should(have_http_status(:unprocessable_entity))
      expect(conn.assigns.param) |> to(eql("panelist_login_name"))
    end
  end

  describe "helper methods" do
    context "add_signup_eligibity_for" do
      it "should add sign up as false if panelist has interviewed candidate" do
        allow Repo |> to(accept(:all, fn(_) -> [1] end))
        interview = build(:interview, candidate_id: 1)

        [resultWithSignUpStatus] = InterviewController.add_signup_eligibity_for([interview], "test")
        expect(resultWithSignUpStatus.signup) |> to(eql(false))
      end

      it "should add sign up as true if panelist has not interviewed any candidate" do
        allow Repo |> to(accept(:all, fn(_) -> [] end))
        interviews = [build(:interview)]

        [resultWithSignUpStatus] = InterviewController.add_signup_eligibity_for(interviews, "test")

        expect(resultWithSignUpStatus.signup) |> to(eql(true))
      end
    end

    context "has_panelist_not_interviewed_candidate" do
      it "should return true when panelist has not interviewed current candidate" do
        interview = build(:interview)

        expect(InterviewController.has_panelist_not_interviewed_candidate([], interview)) |> to(eql(true))
      end

      it "should return false when panelist has interviewed current candidate" do
        interview = build(:interview, candidate_id: 1)
        candidates_interviewed = [interview.candidate_id]

        expect(InterviewController.has_panelist_not_interviewed_candidate(candidates_interviewed, interview)) |> to(eql(false))
      end
    end
  end
end
