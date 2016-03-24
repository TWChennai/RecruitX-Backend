defmodule RecruitxBackend.CandidateControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.CandidateController

  import RecruitxBackend.Factory

  alias Ecto.DateTime
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateController
  alias RecruitxBackend.JSONError
  alias RecruitxBackend.JSONErrorReason

  before do: Repo.delete_all(Candidate)

  let :role, do: create(:role)
  let :interview_rounds, do: convertKeysFromAtomsToStrings(build(:interview_rounds))
  let :valid_attrs, do: Map.merge(fields_for(:candidate, role_id: role.id), Map.merge(interview_rounds, build(:skill_ids)))
  let :post_parameters, do: convertKeysFromAtomsToStrings(Map.merge(valid_attrs, %{other_skills: "other skills"}))

  describe "index" do
    let :candidates do
      Enum.map(create_list(3, :candidate), fn(c) -> c |> Repo.preload(:candidate_skills) end)
    end

    subject do: action :index

    it do: should be_successful
    it do: should have_http_status(:ok)

    it "should return the page number as 2 if candidates are more than 10 and less than 20" do
      create_list(11, :interview, interview_type_id: 1)

      response = action(:index)

      expect(response.assigns.candidates.total_pages) |> to(eq(2))
    end

    it "should return the page number as 2 if candidates is equal to 20" do
      create_list(20, :interview, interview_type_id: 1)

      response = action(:index)

      expect(response.assigns.candidates.total_pages) |> to(eq(2))
    end
  end

  describe "show" do
    let :candidate do
      build(:candidate, id: 1) |> Repo.preload(:candidate_skills)
    end

    before do: allow Repo |> to(accept(:get, fn(_, 1) -> candidate end))

    subject do: action(:show, %{"id" => candidate.id})

    it do: is_expected |> to(be_successful)

    context "not found" do
      before do: allow Repo |> to(accept(:get!, fn(Candidate, 1) -> nil end))

      xit "raises exception" do
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
      it "returns error when skill_ids is empty" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"skill_ids" => []})})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expectedNameErrorReason =  %{"errors" => [%{"skill_ids" => ["missing/empty required key"]}]}
        expect(parsed_response) |> to(be(expectedNameErrorReason))
      end

      it "returns error when skill_ids is not given" do
        response = action(:create, %{"candidate" => Map.delete(post_parameters, "skill_ids")})
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expectedNameErrorReason =  %{"errors" => [%{"skill_ids" => ["missing/empty required key"]}]}
        response |> should(have_http_status(:unprocessable_entity))
        expect(parsed_response) |> to(be(expectedNameErrorReason))
      end

      it "returns error when interview_rounds is empty" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"interview_rounds" => []})})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expectedNameErrorReason = %{"errors" => [%{"interview_rounds" => ["missing/empty required key"]}]}
        expect(parsed_response) |> to(be(expectedNameErrorReason))
      end

      it "returns error when interview_rounds is not given" do
        response = action(:create, %{"candidate" => Map.delete(post_parameters, "interview_rounds")})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expectedNameErrorReason = %{"errors" => [%{"interview_rounds" => ["missing/empty required key"]}]}
        expect(parsed_response) |> to(be(expectedNameErrorReason))
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
      it "when first_name is of invalid format" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"first_name" => "1test"})})

        response |> should(have_http_status(:unprocessable_entity))
        expectedNameErrorReason = %JSONErrorReason{field_name: "first_name", reason: "has invalid format"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedNameErrorReason]})))
      end

      it "when last_name is of invalid format" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"last_name" => "1test"})})

        response |> should(have_http_status(:unprocessable_entity))
        expectedNameErrorReason = %JSONErrorReason{field_name: "last_name", reason: "has invalid format"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedNameErrorReason]})))
      end

      it "when role_id is invalid" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"role_id" => "1.2"})})

        response |> should(have_http_status(:unprocessable_entity))
        expectedRoleErrorReason = %JSONErrorReason{field_name: "role_id", reason: "is invalid"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedRoleErrorReason]})))
      end

      it "when experience is invalid" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"experience" => ""})})

        response |> should(have_http_status(:unprocessable_entity))
        expectedExperienceErrorReason = %JSONErrorReason{field_name: "experience", reason: "is invalid"}
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

      it "when start_time is invalid" do
        post_params_with_invalid_interview_id = Map.merge(post_parameters, %{"interview_rounds" => [%{"interview_type_id" => 1,"start_time" => ""}]})

        response = action(:create, %{"candidate" => post_params_with_invalid_interview_id})

        response |> should(have_http_status(:unprocessable_entity))
        expectedExperienceErrorReason = %JSONErrorReason{field_name: "start_time", reason: "is invalid"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedExperienceErrorReason]})))
      end

      it "when interview_type_id is invalid" do
        post_params_with_invalid_interview_id = Map.merge(post_parameters, %{"interview_rounds" => [%{"interview_type_id" => 1.2, "start_time" => DateTime.utc |> DateTime.to_string}]})

        response = action(:create, %{"candidate" => post_params_with_invalid_interview_id})

        response |> should(have_http_status(:unprocessable_entity))
        expectedExperienceErrorReason = %JSONErrorReason{field_name: "interview_type_id", reason: "is invalid"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedExperienceErrorReason]})))
      end
    end
  end

  describe "methods" do
    context "sendResponseBasedOnResult" do
      it "should send 422(Unprocessable entity) when status is error" do
        response = CandidateController.sendResponseBasedOnResult(conn(), :create, :error, "error")

        response |> should(have_http_status(:unprocessable_entity))
        expectedJSONError = %JSONError{errors: "error"}
        expect(response.resp_body) |> to(be(Poison.encode!(expectedJSONError)))
      end

      it "should send 201 when status is ok" do
        candidate_skill = create(:candidate_skill)
        candidate = Repo.get(Candidate, candidate_skill.candidate_id)
        response = CandidateController.sendResponseBasedOnResult(conn(), :create, :ok, candidate)

        response |> should(have_http_status(:created))
        List.keyfind(response.resp_headers, "location", 0) |> should(be({"location", "/candidates/#{candidate.id}"}))
      end

      it "should send 422(Unprocessable entity) when status is unknown" do
        response = CandidateController.sendResponseBasedOnResult(conn(), :create, :unknown, "unknown")

        response |> should(have_http_status(:unprocessable_entity))
        expectedJSONError = %JSONError{errors: "unknown"}
        expect(response.resp_body) |> to(be(Poison.encode!(expectedJSONError)))
      end
    end
  end
end
