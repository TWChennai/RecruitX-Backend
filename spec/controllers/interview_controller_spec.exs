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
      conn |> should(have_http_status(400))
      expect(conn.assigns.param) |> to(eql("error"))
    end
  end

  describe "helper methods" do
    context "is_signup_lesser_than" do
      it "should return true when signups are lesser than max" do
        interview = create(:interview)
        allow Repo |> to(accept(:all, fn(_) -> [%{"interview_id": interview.id,"signup_count": 1,"interview_type": 1}] end))

        expect(InterviewController.is_signup_lesser_than(interview, 4)) |> to(be_true)
      end

      it "should return false when signups are greater than max" do
        interview = create(:interview)
        allow Repo |> to(accept(:all, fn(_) -> [%{"interview_id": interview.id,"signup_count": 5,"interview_type": 1}] end))

        expect(InterviewController.is_signup_lesser_than(interview, 4)) |> to(be_false)
      end

      it "should return false when signups are equal to max" do
        interview = create(:interview)
        allow Repo |> to(accept(:all, fn(_) -> [%{"interview_id": interview.id,"signup_count": 5,"interview_type": 1}] end))

        expect(InterviewController.is_signup_lesser_than(interview, 4)) |> to(be_false)
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
