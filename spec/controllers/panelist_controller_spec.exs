defmodule RecruitxBackend.PanelistControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.PanelistController

  alias RecruitxBackend.InterviewPanelist

  let :post_parameters, do: convertKeysFromAtomsToStrings(Map.merge(fields_for(:interview_panelist), %{panelist_experience: 2}))

  describe "create" do
    let :interview_panelist, do: create(:interview_panelist)

    context "valid params" do
      before do: allow Repo |> to(accept(:insert, fn(_) -> {:ok, interview_panelist} end))

      it "should return 201 and be successful" do
        conn = action(:create, %{"interview_panelist" => post_parameters})

        conn |> should(be_successful)
        conn |> should(have_http_status(:created))
      end
    end

    context "invalid changeset due to constraints on insertion to database" do
      before do: allow Repo |> to(accept(:insert, fn(_) -> {:error, InterviewPanelist.changeset(%InterviewPanelist{}, %{})} end))
      it "should return 422(Unprocessable entity) and the reason" do
        response = action(:create, %{"interview_panelist" => post_parameters})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expect(parsed_response) |> to(be(%{"errors" => %{"panelist_login_name" => ["can't be blank"], "interview_id" =>["can't be blank"]}}))
      end
    end

    context "invalid params" do
      it "returns error when panelist_login_name is not given" do
        response = action(:create, %{"interview_panelist" => Map.delete(post_parameters, "panelist_login_name")})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expect(parsed_response) |> to(be(%{"errors" => %{"panelist_login_name" => ["can't be blank"]}}))
      end

      it "returns error when interview_id is not given" do
        response = action(:create, %{"interview_panelist" => Map.delete(post_parameters, "interview_id")})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expect(parsed_response) |> to(be(%{"errors" => %{"interview_id" => ["can't be blank"]}}))
      end

      it "returns error when panelist_login_name is invalid" do
        response = action(:create, %{"interview_panelist" => Map.merge(post_parameters, %{"panelist_login_name" => "1test"})})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expect(parsed_response) |> to(be(%{"errors" => %{"panelist_login_name" => ["has invalid format"]}}))
      end

      it "returns error when interview_id is invalid" do
        response = action(:create, %{"interview_panelist" => Map.merge(post_parameters, %{"interview_id" => "1test"})})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expect(parsed_response) |> to(be(%{"errors" => %{"interview_id" => ["is invalid"]}}))
      end
    end
  end

  describe "delete action" do
    let :candidate, do: create(:candidate)
    let :interview, do: create(:interview, candidate_id: candidate.id)
    let :interview_panelist, do: create(:interview_panelist, interview_id: interview.id)
    let :email, do: %{subject: "[RecruitX] Update on the Interview for #{candidate.first_name} #{candidate.last_name}", to: interview_panelist.panelist_login_name <> System.get_env("EMAIL_POSTFIX") |> String.split, html: "html content"}

    it "should send email to signed up panelist" do
      allow MailmanExtensions.Templates |> to(accept(:panelist_removal_notification, fn(_, _, _) -> "html content"  end))
      allow MailmanExtensions.Mailer |> to(accept(:deliver, fn(_) -> "" end))

      action(:delete, %{"id" => interview_panelist.id})

      expect MailmanExtensions.Templates |> to(accepted :panelist_removal_notification)
      expect MailmanExtensions.Mailer |> to(accepted :deliver, [email])
    end
  end
end
