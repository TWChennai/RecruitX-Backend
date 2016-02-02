defmodule RecruitxBackend.InterviewPanelistControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.InterviewPanelistController

  alias RecruitxBackend.InterviewPanelistController
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.JSONError

  let :post_parameters, do: convertKeysFromAtomsToStrings(fields_for(:interview_panelist))

  describe "create" do
    let :interview_panelist, do: create(:interview_panelist)

    context "valid params" do
      before do: allow Repo |> to(accept(:insert, fn(_) -> {:ok, interview_panelist} end))

      it "should return 201 and be successful" do
        conn = action(:create, %{"interview_panelist" => post_parameters})

        conn |> should(be_successful)
        conn |> should(have_http_status(:created))
        List.keyfind(conn.resp_headers, "location", 0) |> should(be({"location", "/interview_panelists/#{interview_panelist.id}"}))
      end
    end

    context "invalid changeset due to constraints on insertion to database" do
      before do: allow Repo |> to(accept(:insert, fn(_) -> {:error, %Ecto.Changeset{ errors: [test: "does not exist"]}} end))

      it "should return 422(Unprocessable entity) and the reason" do
        response = action(:create, %{"interview_panelist" => post_parameters})
        response |> should(have_http_status(:unprocessable_entity))
        expectedNameErrorReason = %JSONErrorReason{field_name: "test", reason: "does not exist"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedNameErrorReason]})))
      end
    end

    context "invalid params" do
      it "returns error when panelist_login_name is not given" do
        response = action(:create, %{"interview_panelist" => Map.delete(post_parameters, "panelist_login_name")})
        response |> should(have_http_status(:unprocessable_entity))
        expectedNameErrorReason = %JSONErrorReason{field_name: "panelist_login_name", reason: "can't be blank"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedNameErrorReason]})))
      end

      it "returns error when interview_id is not given" do
        response = action(:create, %{"interview_panelist" => Map.delete(post_parameters, "interview_id")})
        response |> should(have_http_status(:unprocessable_entity))
        expectedNameErrorReason = %JSONErrorReason{field_name: "interview_id", reason: "can't be blank"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedNameErrorReason]})))
      end

      it "returns error when panelist_login_name is invalid" do
        response = action(:create, %{"interview_panelist" => Map.merge(post_parameters, %{"panelist_login_name" => "1test"})})
        response |> should(have_http_status(:unprocessable_entity))
        expectedNameErrorReason = %JSONErrorReason{field_name: "panelist_login_name", reason: "has invalid format"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedNameErrorReason]})))
      end

      it "returns error when interview_id is invalid" do
        response = action(:create, %{"interview_panelist" => Map.merge(post_parameters, %{"interview_id" => "1test"})})
        response |> should(have_http_status(:unprocessable_entity))
        expectedNameErrorReason = %JSONErrorReason{field_name: "interview_id", reason: "is invalid"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedNameErrorReason]})))
      end
    end
  end

  describe "methods" do
    context "sendResponseBasedOnResult" do
      it "should send 422(Unprocessable entity) when status is error" do
        response = InterviewPanelistController.sendResponseBasedOnResult(conn(), :create, :error, "error")

        response |> should(have_http_status(:unprocessable_entity))
        expectedJSONError = %JSONError{errors: "error"}
        expect(response.resp_body) |> to(be(Poison.encode!(expectedJSONError)))
      end

      it "should send 201 when status is ok" do
        interview_panelist = create(:interview_panelist)
        response = InterviewPanelistController.sendResponseBasedOnResult(conn(), :create, :ok, interview_panelist)

        response |> should(have_http_status(:created))
        expect(response.resp_body) |> to(be(Poison.encode!(interview_panelist)))
        List.keyfind(response.resp_headers, "location", 0) |> should(be({"location", "/interview_panelists/#{interview_panelist.id}"}))
      end

      it "should send 422(Unprocessable entity) when status is unknown" do
        response = InterviewPanelistController.sendResponseBasedOnResult(conn(), :create, :unknown, "unknown")

        response |> should(have_http_status(:unprocessable_entity))
        expectedJSONError = %JSONError{errors: "unknown"}
        expect(response.resp_body) |> to(be(Poison.encode!(expectedJSONError)))
      end
    end
  end
end
