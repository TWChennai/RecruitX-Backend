defmodule RecruitxBackend.CandidateIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.CandidateController

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint

  require Ecto.Query

  alias Ecto.Query
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill

  describe "get /candidates" do
    before do:  Repo.delete_all(Candidate)

    it "should return a list of candidates" do
      candidate = create(:candidate)

      response = get conn(), "/candidates"

      expect(response.status) |> to(be(200))
      expect(response.resp_body) |> to(be(Poison.encode!([candidate], keys: :atoms!)))
    end
  end

  describe "POST /candidates" do
    before do:  Repo.delete_all(Candidate)

    context "with valid params" do
      it "should create a new candidate and insert corresponding skill in the db" do
        orig_candidate_count = get_candidate_count
        post_skill_params = build(:skill_ids)
        post_parameters = Map.merge(fields_for(:candidate),Map.merge(post_skill_params, build(:interview_rounds)))
        response = post conn(), "/candidates", %{"candidate" => post_parameters}

        expect(response.status) |> to(be(200))

        new_candidate_count = get_candidate_count
        expect(new_candidate_count) |> to(be(orig_candidate_count + 1))
        candidate_skill = get_candidate_skill_ids_for(post_parameters[:name])
        unique_skill_ids = Enum.uniq(post_skill_params.skill_ids)
        expect(candidate_skill) |> to(be(unique_skill_ids))
      end
    end

    context "with invalid params" do
      it "should not create a new candidate in the db" do
        orig_candidate_count = get_candidate_count

        response = post conn(), "/candidates", %{"candidate" => Map.merge(build(:skill_ids), build(:interview_rounds))}

        expect(response.status) |> to(be(400))
        new_candidate_count = get_candidate_count
        expect(new_candidate_count) |> to(be(orig_candidate_count))
      end
    end

     context "with no POST params" do
       xit "should return 400(Bad Request)" do
        orig_candidate_count = get_candidate_count

        response = post conn(), "/candidates"
        expect(response.status) |> to(be(400))
        new_candidate_count = get_candidate_count
        expect(new_candidate_count) |> to(be(orig_candidate_count))
       end
     end

    def get_candidate_count do
      Ectoo.count(Repo, Candidate)
    end

    def get_candidate_skill_ids_for(name) do
      q = CandidateSkill
        |> Query.join(:inner, [cs], c in Candidate, c.name == ^name and c.id == cs.candidate_id)
        |> Query.select([cs], cs.skill_id)
      Repo.all q
    end
  end
end
