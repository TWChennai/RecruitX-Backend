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

  xdescribe "index" do
  end

  describe "helper methods" do
    context "addSignUpEigibityFor" do
      it "should add sign up as false if panelist has interviewed candidate" do
        allow Repo |> to(accept(:all, fn(_) -> [1] end))
        interview = build(:interview, candidate_id: 1)

        [resultWithSignUpStatus] = InterviewController.addSignUpEigibityFor([interview], "test")
        expect(resultWithSignUpStatus.sign_up) |> to(eql(false))
      end

      it "should add sign up as true if panelist has not interviewed any candidate" do
        allow Repo |> to(accept(:all, fn(_) -> [] end))
        interviews = [build(:interview)]

        [resultWithSignUpStatus] = InterviewController.addSignUpEigibityFor(interviews, "test")

        expect(resultWithSignUpStatus.sign_up) |> to(eql(true))
      end
    end

    context "hasPanelistNotInterviewedCandidate" do
      it "should return true when panelist has not interviewed current candidate" do
        interview = build(:interview)

        expect(InterviewController.hasPanelistNotInterviewedCandidate([], interview)) |> to(eql(true))
      end

      it "should return false when panelist has interviewed current candidate" do
        interview = build(:interview, candidate_id: 1)
        candidates_interviewed = [interview.candidate_id]

        expect(InterviewController.hasPanelistNotInterviewedCandidate(candidates_interviewed, interview)) |> to(eql(false))
      end
    end
  end
end
