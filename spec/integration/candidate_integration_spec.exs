defmodule RecruitxBackend.CandidateIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.CandidateController

  import Ecto.Query

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Role

  describe "get /candidates" do
    it "should return a list of candidates" do
      role = Repo.insert!(%Role{name: "test_role"})
      {:ok, candidate} = Repo.insert(Candidate.changeset(%Candidate{}, %{"name" => "test", "experience" => Decimal.new(2.12), "role_id" => role.id}))

      response = get conn(), "/candidates"

      expect(response.status) |> to(be(200))
      expect(response.resp_body) |> to(be(Poison.encode!([candidate], keys: :atoms!)))
    end
  end

  describe "POST /candidates" do
    context "with valid params" do
      it "should create a new candidate in the db" do
        role = Repo.insert!(%Role{name: "test_role"})
        orig_candidate_count = get_candidate_count

        response = post conn(), "/candidates", [name: "test", role_id: role.id, experience: Decimal.new(3)]

        expect(response.status) |> to(be(200))
        new_candidate_count = get_candidate_count
        expect(new_candidate_count) |> to(be(orig_candidate_count + 1))
      end
    end

    context "with invalid params" do
      it "should not create a new candidate in the db" do
        orig_candidate_count = get_candidate_count

        response = post conn(), "/candidates", [invalid: "invalid_post_param"]

        expect(response.status) |> to(be(400))
        new_candidate_count = get_candidate_count
        expect(new_candidate_count) |> to(be(orig_candidate_count))
      end
    end

    context "with no POST params" do
      it "should return 400(Bad Request)" do
        orig_candidate_count = get_candidate_count

        response = post conn(), "/candidates"

        expect(response.status) |> to(be(400))
        new_candidate_count = get_candidate_count
        expect(new_candidate_count) |> to(be(orig_candidate_count))
      end
    end

    def get_candidate_count do
      Repo.one(from candidates in Candidate, select: count(candidates.id))
    end
  end
end
