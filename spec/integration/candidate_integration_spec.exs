defmodule RecruitxBackend.CandidateIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.CandidateController

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint

  import Ecto.Query, only: [from: 2]

  alias RecruitxBackend.Candidate

  describe "get /candidates" do
    before do:  Repo.delete_all(Candidate)

    xit "should return a list of candidates" do
      candidate_skill = create(:candidate_skill)
      # Can't take the complete candidate object since it has 'role' associated
      candidate = Repo.get!(Candidate, candidate_skill.candidate_id) |> Repo.preload(:candidate_skills)

      response = get conn(), "/candidates"

      expect(response.status) |> to(be(200))
      expect(response.assigns.candidates) |> to(be([candidate]))
    end
  end

  describe "update /candidates/:id" do
    it "should update and return the candidate" do
      candidate = create(:candidate)

      response = put conn(), "/candidates/#{candidate.id}", %{"candidate" => %{name: "test"}}

      updated_candidate = Map.merge(candidate, %{name: "test"})
      response |> should(have_http_status(200))
      expect(response.assigns.candidate) |> to(be(updated_candidate))
    end

    it "should not update and return errors when invalid change" do
      candidate = create(:candidate)

      response = put conn(), "/candidates/#{candidate.id}", %{"candidate" => %{name: "test1"}}

      response |> should(have_http_status(:unprocessable_entity))
      expect(response.assigns.changeset.errors) |> to(be([name: "has invalid format"]))
      expect(Candidate |> Repo.get(candidate.id)) |> to(be(candidate))
    end

    it "should return 404 when candidate is not found" do
      response = put conn(), "/candidates/0", %{"candidate" => %{name: "test"}}

      response |> should(have_http_status(:not_found))
    end
  end

  describe "POST /candidates" do
    context "with valid params" do
      it "should create a new candidate and insert corresponding skill, interview round in the db" do
        orig_candidate_count = get_candidate_count
        post_skill_params = build(:skill_ids)
        candidate_params = fields_for(:candidate, experience: 6.21)
        interview_round_params = build(:interview_rounds)
        post_parameters = Map.merge(candidate_params, Map.merge(post_skill_params, interview_round_params))

        response = post conn(), "/candidates", %{"candidate" => post_parameters}

        expect(response.status) |> to(be(201))
        inserted_candidate = getCandidateWithName(candidate_params.name)
        List.keyfind(response.resp_headers, "location", 0) |> should(be({"location", "/candidates/#{inserted_candidate.id}"}))

        new_candidate_count = get_candidate_count
        expect(new_candidate_count) |> to(be(orig_candidate_count + 1))
        assertInsertedSkillIdsFor(inserted_candidate, post_skill_params.skill_ids)
        assertInsertedInterviewRoundsFor(inserted_candidate, interview_round_params)
      end
    end

    context "with invalid params" do
      it "should not create a new candidate in the db" do
        orig_candidate_count = get_candidate_count

        response = post conn(), "/candidates", %{"candidate" => Map.merge(build(:skill_ids), build(:interview_rounds))}

        expect(response.status) |> to(be(422))
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

    defp getCandidateWithName(name) do
      query = from c in Candidate, where: ilike(c.name, ^"%#{name}%"), preload: [:candidate_skills, :interviews]
      Repo.one(query)
    end

    defp get_candidate_count do
      Ectoo.count(Repo, Candidate)
    end

    defp get_candidate_skill_ids_for(candidate) do
      for skill <- candidate.candidate_skills, do: skill.skill_id
    end

    defp assertInsertedSkillIdsFor(inserted_candidate, skill_ids) do
      candidate_skills = get_candidate_skill_ids_for(inserted_candidate)
      unique_skill_ids = Enum.uniq(skill_ids)
      expect(candidate_skills) |> to(be(unique_skill_ids))
    end

    defp assertInsertedInterviewRoundsFor(candidate, interview_rounds_params) do
      interview_to_insert = interview_rounds_params[:interview_rounds]
      interview_inserted = candidate.interviews

      for index <- 0..Dict.size(interview_to_insert) - 1 do
        %{"interview_type_id" => id, "start_time" => date_time} = Enum.at(interview_to_insert, index)
        interview_round = Enum.at(interview_inserted, index)

        expect(interview_round.interview_type_id) |> to(be(id))
        expect(interview_round.start_time) |> to(be(date_time))
      end
    end
  end
end
