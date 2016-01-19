defmodule RecruitxBackend.CandidateControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.CandidateController

  import RecruitxBackend.Factory

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.JSONErrorReason
  alias RecruitxBackend.JSONError

  let :valid_attrs, do: fields_for(:candidate, role_id: create(:role).id, skill_ids: [2])
  let :post_parameters, do: convertKeysFromAtomsToStrings(valid_attrs)

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
    let :candidate, do: %Candidate{id: 1, title: "Candidate title", body: "some body content"}

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

    describe "valid params" do
      before do: allow Repo |> to(accept(:insert, fn(_) -> {:ok, create(:candidate)} end))

      it "should return 200 and be successful" do
        conn = action(:create, %{"candidate" => post_parameters})

        conn |> should(be_successful)
        conn |> should(have_http_status(200))
      end
    end

    context "invalid query params" do
      let :invalid_attrs_with_empty_skill_id, do: %{"candidate" => %{"skill_ids" => []}}
      let :invalid_attrs_with_no_skill_id, do: %{"candidate" => %{}}
      let :invalid_attrs_with_no_candidate_key, do: %{}

      it "raises exception when skill_ids is empty" do
        expect(fn -> action(:create, invalid_attrs_with_empty_skill_id) end) |> to(raise_exception(Phoenix.MissingParamError))
      end

      it "raises exception when skill_ids is not given" do
        expect(fn -> action(:create, invalid_attrs_with_no_skill_id) end) |> to(raise_exception(Phoenix.MissingParamError))
      end

      it "when name is of invalid format" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"name" => "1test"})})

        response |> should(have_http_status(400))
        expectedNameErrorReason = %JSONErrorReason{field_name: "name", reason: "has invalid format"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedNameErrorReason]})))
      end

      it "when role_id is invalid" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"role_id" => "1.2"})})

        response |> should(have_http_status(400))
        expectedRoleErrorReason = %JSONErrorReason{field_name: "role_id", reason: "is invalid"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedRoleErrorReason]})))
      end

      it "when experience is invalid" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"experience" => ""})})

        response |> should(have_http_status(400))
        expectedExperienceErrorReason = %JSONErrorReason{field_name: "experience", reason: "is invalid"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedExperienceErrorReason]})))
      end

      it "when experience is out of range" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"experience" => "-1"})})

        response |> should(have_http_status(400))
        expectedExperienceErrorReason = %JSONErrorReason{field_name: "experience", reason: "must be in the range 0-100"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedExperienceErrorReason]})))
      end

      it "when experience is out of range" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"experience" => "-1"})})

        response |> should(have_http_status(400))
        expectedExperienceErrorReason = %JSONErrorReason{field_name: "experience", reason: "must be in the range 0-100"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedExperienceErrorReason]})))
      end

      it "when skill_id is invalid" do
        response = action(:create, %{"candidate" => Map.merge(post_parameters, %{"skill_ids" => [1.2]})})

        response |> should(have_http_status(400))
        expectedExperienceErrorReason = %JSONErrorReason{field_name: "skill_id", reason: "is invalid"}
        expect(response.resp_body) |> to(be(Poison.encode!(%JSONError{errors: [expectedExperienceErrorReason]})))
      end
    end
  end

  def convertKeysFromAtomsToStrings(input) do
    for {key, val} <- input, into: %{}, do: {to_string(key), val}
  end
end
