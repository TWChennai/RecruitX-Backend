defmodule RecruitxBackend.CandidateControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.CandidateController

  import RecruitxBackend.Factory

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateController
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.JSONError
  alias Ecto.DateTime

  let :interview_rounds, do: convertKeysFromAtomsToStrings(build(:interview_rounds))
  let :valid_attrs, do: Map.merge(fields_for(:candidate), Map.merge(interview_rounds, build(:skill_ids)))
  let :post_parameters, do: convertKeysFromAtomsToStrings(Map.merge(valid_attrs, %{additional_information: "addn info"}))

  describe "index" do
    let :candidates do
      [
        build(:candidate, additional_information: "Candidate addn info1"),
        build(:candidate, additional_information: "Candidate addn info2"),
      ]
    end

    before do: allow Repo |> to(accept(:all, fn(_) -> candidates end))

    subject do: action :index

    it do: should be_successful
    it do: should have_http_status(:ok)

    it "should return the array of candidates as a JSON response" do
      response = action(:index)

      expect(response.resp_body) |> to(eq(Poison.encode!(candidates, keys: :atoms!)))
    end
  end

  xdescribe "show" do
    let :candidate, do: build(:candidate, id: 1)

    before do: allow Repo |> to(accept(:get!, fn(Candidate, 1) -> candidate end))

    subject do: action(:show, %{"id" => 1})

    it do: is_expected |> to(be_successful)

    context "not found" do
      before do: allow Repo |> to(accept(:get!, fn(Candidate, 1) -> nil end))

      it "raises exception" do
        expect(fn -> action(:show, %{"id" => 1}) end) |> to(raise_exception)
      end
    end
  end

  describe "create" do
    let :valid_changeset, do: %{:valid? => true}
    let :invalid_changeset, do: %{:valid? => false}
    let :created_candidate, do: create(:candidate)

    describe "valid params" do
      before do: allow Repo |> to(accept(:insert, fn(_) -> {:ok, created_candidate} end))

      it "should return 201 and be successful" do
        conn = action(:create, %{"candidate" => post_parameters})

        conn |> should(be_successful)
        conn |> should(have_http_status(:created))
        List.keyfind(conn.resp_headers, "location", 0) |> should(be({"location", "/candidates/#{created_candidate.id}"}))
      end
    end

    context "invalid query params" do
      let :invalid_attrs_with_empty_skill_id, do: %{"candidate" => %{"skill_ids" => []}}
      let :invalid_attrs_with_no_skill_id, do: %{"candidate" => %{}}
      let :invalid_attrs_with_empty_interview_rounds, do: %{"candidate" => %{"interview_rounds" => []}}
      let :invalid_attrs_with_no_interview_round, do: %{"candidate" => %{}}

      it "raises exception when skill_ids is empty" do
        expect(fn -> action(:create, invalid_attrs_with_empty_skill_id) end) |> to(raise_exception(Phoenix.MissingParamError))
      end

      it "raises exception when skill_ids is not given" do
        expect(fn -> action(:create, invalid_attrs_with_no_skill_id) end) |> to(raise_exception(Phoenix.MissingParamError))
      end

      it "raises exception when interview_rounds is empty" do
        expect(fn -> action(:create, invalid_attrs_with_empty_interview_rounds) end) |> to(raise_exception(Phoenix.MissingParamError))
      end

      it "raises exception when interview_rounds is not given" do
        expect(fn -> action(:create, invalid_attrs_with_no_interview_round) end) |> to(raise_exception(Phoenix.MissingParamError))
      end
    end

    context "invalid changeset due to constraints on insertion to database" do
      before do: allow Repo |> to(accept(:insert, fn(_) -> {:error, %Ecto.Changeset{ errors: [test: "does not exist"]}} end))

      it "should return 422(Unprocessable entity) and the reason" do
        response = action(:create, %{"candidate" => post_parameters})
        response |> should(have_http_status(:unprocessable_entity))
        expectedNameErrorReason = %JSONErrorReason{field_name: "test", reason: "does not exist"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedNameErrorReason]})))
      end
    end

    context "invalid changeset on validation before insertion to database" do
      it "when name is of invalid format" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"name" => "1test"})})

        response |> should(have_http_status(:unprocessable_entity))
        expectedNameErrorReason = %JSONErrorReason{field_name: "name", reason: "has invalid format"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedNameErrorReason]})))
      end

      it "when role_id is invalid" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"role_id" => "1.2"})})

        response |> should(have_http_status(:unprocessable_entity))
        expectedRoleErrorReason = %JSONErrorReason{field_name: "role_id", reason: "can't be blank"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedRoleErrorReason]})))
      end

      it "when experience is invalid" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"experience" => ""})})

        response |> should(have_http_status(:unprocessable_entity))
        expectedExperienceErrorReason = %JSONErrorReason{field_name: "experience", reason: "can't be blank"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedExperienceErrorReason]})))
      end

      it "when experience is out of range" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"experience" => "-1"})})

        response |> should(have_http_status(:unprocessable_entity))
        expectedExperienceErrorReason = %JSONErrorReason{field_name: "experience", reason: "must be in the range 0-100"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedExperienceErrorReason]})))
      end

      it "when experience is out of range" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"experience" => "100"})})

        response |> should(have_http_status(:unprocessable_entity))
        expectedExperienceErrorReason = %JSONErrorReason{field_name: "experience", reason: "must be in the range 0-100"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedExperienceErrorReason]})))
      end

      it "when skill_id is invalid" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"skill_ids" => [1.2]})})

        response |> should(have_http_status(:unprocessable_entity))
        expectedExperienceErrorReason = %JSONErrorReason{field_name: "skill_id", reason: "is invalid"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedExperienceErrorReason]})))
      end

      it "when interview_date_time is invalid" do
        post_params_with_invalid_interview_id = Map.merge(post_parameters, %{"interview_rounds" => [%{"interview_id" => 1,"interview_date_time" => ""}]})

        response = action(:create, %{"candidate" => post_params_with_invalid_interview_id})

        response |> should(have_http_status(:unprocessable_entity))
        expectedExperienceErrorReason = %JSONErrorReason{field_name: "candidate_interview_date_time", reason: "is invalid"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedExperienceErrorReason]})))
      end

      it "when interview_id is invalid" do
        post_params_with_invalid_interview_id = Map.merge(post_parameters, %{"interview_rounds" => [%{"interview_id" => 1.2, "interview_date_time" => DateTime.utc |> DateTime.to_string}]})

        response = action(:create, %{"candidate" => post_params_with_invalid_interview_id})

        response |> should(have_http_status(:unprocessable_entity))
        expectedExperienceErrorReason = %JSONErrorReason{field_name: "interview_id", reason: "is invalid"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedExperienceErrorReason]})))
      end
    end
  end

  describe "methods" do
    context "getChangesetErrorsInReadableFormat" do
      it "when errors is in the form of string" do
        [result] = CandidateController.getChangesetErrorsInReadableFormat(%{errors: [test: "is invalid"]})

        expect(result.field_name) |> to(eql(:test))
        expect(result.reason) |> to(eql("is invalid"))
      end

      it "when there are multiple errors" do
        [result1,result2] = CandidateController.getChangesetErrorsInReadableFormat(%{errors: [error1: "is invalid", error2: "is also invalid"]})

        expect(result1.field_name) |> to(eql(:error1))
        expect(result1.reason) |> to(eql("is invalid"))
        expect(result2.field_name) |> to(eql(:error2))
        expect(result2.reason) |> to(eql("is also invalid"))
      end

      it "when errors is in the form of tuple" do
        [result] = CandidateController.getChangesetErrorsInReadableFormat(%{errors: [test: {"value1", "value2"}]})

        expect(result.field_name) |> to(eql(:test))
        expect(result.reason) |> to(eql("value1"))
      end

      it "when there are no errors" do
        result = CandidateController.getChangesetErrorsInReadableFormat(%{})

        expect(result) |> to(eql([]))
      end
    end

    context "sendResponseBasedOnResult" do
      it "should send 422(Unprocessable entity) when status is error" do
        response = CandidateController.sendResponseBasedOnResult(conn(), :error, "error")

        response |> should(have_http_status(:unprocessable_entity))
        expectedJSONError = %JSONError{errors: "error"}
        expect(response.resp_body) |> to(be(Poison.encode!(expectedJSONError)))
      end

      it "should send 201 when status is ok" do
        candidate = build(:candidate, id: 1)
        response = CandidateController.sendResponseBasedOnResult(conn(), :ok, candidate)

        response |> should(have_http_status(:created))
        expect(response.resp_body) |> to(be(Poison.encode!(candidate)))
        List.keyfind(response.resp_headers, "location", 0) |> should(be({"location", "/candidates/#{candidate.id}"}))
      end

      it "should send 422(Unprocessable entity) when status is unknown" do
        response = CandidateController.sendResponseBasedOnResult(conn(), :unknown, "unknown")

        response |> should(have_http_status(:unprocessable_entity))
        expectedJSONError = %JSONError{errors: "unknown"}
        expect(response.resp_body) |> to(be(Poison.encode!(expectedJSONError)))
      end
    end

    context "getCandidateProfileParams" do
      it "should pick valid fields from post request paramters" do
        result = CandidateController.getCandidateProfileParams(post_parameters)

        expect(result.name) |> to(eql(valid_attrs.name))
        expect(result.role_id) |> to(eql(valid_attrs.role_id))
        expect(result.experience) |> to(eql(valid_attrs.experience))
        expect(result.additional_information) |> to(eql(post_parameters["additional_information"]))
      end

      it "should pick valid fields from post request paramters and rest of the fields as nil" do
        result = CandidateController.getCandidateProfileParams(Map.delete(post_parameters, "name"))

        expect(result.role_id) |> to(eql(valid_attrs.role_id))
        expect(result.experience) |> to(eql(valid_attrs.experience))
        expect(result.additional_information) |> to(eql(post_parameters["additional_information"]))
      end

      it "should return all fields as nil if post parameter is empty map" do
        result = CandidateController.getCandidateProfileParams(%{})
        expect(result) |> to(eql(%{}))
      end
    end
  end

  def convertKeysFromAtomsToStrings(input) do
    for {key, val} <- input, into: %{}, do: {to_string(key), val}
  end
end
