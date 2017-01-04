defmodule RecruitxBackend.PanelistControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.PanelistController

  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.TeamDetailsUpdate

  let :post_parameters, do: convertKeysFromAtomsToStrings(Map.merge(params_with_assocs(:interview_panelist), %{"panelist_experience" => 2, "panelist_role" => "Dev"}))
  before do: allow TeamDetailsUpdate |> to(accept(:update_in_background, fn(_, _) -> true end))

  describe "create" do
    let :interview_panelist, do: insert(:interview_panelist, panelist_login_name: "test")

    context "valid params for interview_panelist" do
      before do: allow Repo |> to(accept(:insert, fn(_) -> {:ok, interview_panelist()} end))

      it "should return 201 and be successful" do
        conn = action(:create, %{"interview_panelist" => post_parameters()})

        conn |> should(be_successful())
        conn |> should(have_http_status(:created))
      end
    end

    context "valid params for slot_panelist" do
      let :slot_panelist, do: insert(:slot_panelist)

      before do: allow Repo |> to(accept(:insert, fn(_) -> {:ok, slot_panelist()} end))

      it "should return 201 and be successful" do
        conn = action(:create, %{"slot_panelist" => post_parameters()})

        conn |> should(be_successful())
        conn |> should(have_http_status(:created))
      end
    end

    context "invalid changeset due to constraints on insertion to database" do
      before do: allow Repo |> to(accept(:insert, fn(_) -> {:error, InterviewPanelist.changeset(%InterviewPanelist{}, %{})} end))
      it "should return 422(Unprocessable entity) and the reason" do
        response = action(:create, %{"interview_panelist" => post_parameters()})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expect(parsed_response) |> to(be(%{"errors" => %{"panelist_login_name" => ["can't be blank"], "interview_id" =>["can't be blank"]}}))
      end
    end

    context "invalid params" do
      it "returns error when panelist_login_name is not given" do
        response = action(:create, %{"interview_panelist" => Map.delete(post_parameters(), "panelist_login_name")})
        response |> should(have_http_status(:bad_request))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expectedErrorReason =  %{"field" => "panelist_experience/panelist_role/panelist_login_name", "reason" => "missing/empty required parameter"}
        expect(parsed_response) |> to(be(expectedErrorReason))
      end

      it "returns error when interview_id is not given" do
        response = action(:create, %{"interview_panelist" => Map.delete(post_parameters(), "interview_id")})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expect(parsed_response) |> to(be(%{"errors" => %{"interview_id" => ["can't be blank"]}}))
      end

      it "returns error when panelist_login_name is invalid" do
        response = action(:create, %{"interview_panelist" => Map.merge(post_parameters(), %{"panelist_login_name" => "1test"})})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expect(parsed_response) |> to(be(%{"errors" => %{"panelist_login_name" => ["has invalid format"]}}))
      end

      it "returns error when interview_id is invalid" do
        response = action(:create, %{"interview_panelist" => Map.merge(post_parameters(), %{"interview_id" => "1test"})})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expect(parsed_response) |> to(be(%{"errors" => %{"interview_id" => ["is invalid"]}}))
      end
    end
  end
end
