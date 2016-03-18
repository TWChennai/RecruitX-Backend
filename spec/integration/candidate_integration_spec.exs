defmodule RecruitxBackend.CandidateIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.CandidateController

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.PipelineStatus
  alias Timex.Date

  describe "get /candidates" do
    before do:  Repo.delete_all(Candidate)

    it "should return a list of candidates" do
      interview1 = create(:interview, interview_type_id: 1, start_time: Date.now)
      interview2 = create(:interview, interview_type_id: 1, start_time: Date.now |> Date.shift(hours: 1))
      candidate1 = Candidate |> Repo.get(interview1.candidate_id)
      candidate2 = Candidate |> Repo.get(interview2.candidate_id)

      response = get conn_with_dummy_authorization(), "/candidates"

      expect(response.status) |> to(be(200))
      expect(response.assigns.candidates.total_pages) |> to(eq(1))
      expect(response.assigns.candidates.entries) |> to(eq([candidate1, candidate2]))
    end

    it "should return a candidates with and without interviews " do
      interview1 = create(:interview, interview_type_id: 1, start_time: Date.now)
      candidate1 = Candidate |> Repo.get(interview1.candidate_id)
      candidate2 = create(:candidate)

      response = get conn_with_dummy_authorization(), "/candidates"

      expect(response.status) |> to(be(200))
      expect(response.assigns.candidates.total_pages) |> to(eq(1))
      expect(response.assigns.candidates.entries) |> to(eq([candidate1, candidate2]))
    end
  end

  describe "update /candidates/:id" do
    it "should update and return the candidate" do
      candidate = create(:candidate)

      response = put conn_with_dummy_authorization(), "/candidates/#{candidate.id}", %{"candidate" => %{first_name: "test"}}

      updated_candidate = Map.merge(candidate, %{first_name: "test"})
      response |> should(have_http_status(200))
      expect(response.assigns.candidate.first_name) |> to(be(updated_candidate.first_name))
    end

    it "should not update and return errors when invalid change" do
      candidate = create(:candidate)

      response = put conn_with_dummy_authorization(), "/candidates/#{candidate.id}", %{"candidate" => %{first_name: "test1"}}

      response |> should(have_http_status(:unprocessable_entity))
      expect(response.assigns.changeset.errors) |> to(be([first_name: "has invalid format"]))
      expect(Candidate |> Repo.get(candidate.id)) |> to(be(candidate))
    end

    it "should return 404 when candidate is not found" do
      response = put conn_with_dummy_authorization(), "/candidates/0", %{"candidate" => %{first_name: "test"}}

      response |> should(have_http_status(:not_found))
    end

    it "should update the candidate and delete the successive interviews and panelists if the update is for closing the pipeline" do
      candidate = create(:candidate)
      interview = create(:interview, %{candidate_id: candidate.id, start_time: Date.now |> Date.shift(days: 1)})
      interview_panelist = create(:interview_panelist, interview_id: interview.id)
      closed_pipeline_status_id = PipelineStatus.retrieve_by_name(PipelineStatus.closed).id

      response = put conn_with_dummy_authorization(), "/candidates/#{candidate.id}", %{"candidate" => %{"pipeline_status_id" => closed_pipeline_status_id}}

      updated_candidate = Map.merge(candidate, %{pipeline_status_id: closed_pipeline_status_id})
      response |> should(have_http_status(200))
      expect(response.assigns.candidate) |> to(be(updated_candidate))
      expect(Interview |> Repo.get(interview.id)) |> to(be_nil)
      expect(InterviewPanelist |> Repo.get(interview_panelist.id)) |> to(be_nil)
    end

    it "should update the candidate and delete previous interviews and panelists if the update is for closing the pipeline and if interview_status_id is nil" do
      candidate = create(:candidate)
      interview = create(:interview, candidate_id: candidate.id, start_time: Date.now |> Date.shift(days: -1))
      create(:interview_panelist, interview_id: interview.id)
      closed_pipeline_status_id = PipelineStatus.retrieve_by_name(PipelineStatus.closed).id

      response = put conn_with_dummy_authorization(), "/candidates/#{candidate.id}", %{"candidate" => %{"pipeline_status_id" => closed_pipeline_status_id}}

      updated_candidate = Map.merge(candidate, %{pipeline_status_id: closed_pipeline_status_id})
      response |> should(have_http_status(200))
      expect(response.assigns.candidate) |> to(be(updated_candidate))
      expect(Interview |> Repo.get(interview.id)) |> to(be(nil))
    end

    it "should update the candidate and not delete previous interviews and panelists if the update is for closing the pipeline and if interview_status_id is not nil" do
      candidate = create(:candidate)
      interview = create(:interview, candidate_id: candidate.id, start_time: Date.now |> Date.shift(days: -1), interview_status_id: 1)
      interview_panelist = create(:interview_panelist, interview_id: interview.id)
      closed_pipeline_status_id = PipelineStatus.retrieve_by_name(PipelineStatus.closed).id

      response = put conn_with_dummy_authorization(), "/candidates/#{candidate.id}", %{"candidate" => %{"pipeline_status_id" => closed_pipeline_status_id}}

      updated_candidate = Map.merge(candidate, %{pipeline_status_id: closed_pipeline_status_id})
      response |> should(have_http_status(200))
      expect(response.assigns.candidate) |> to(be(updated_candidate))
      expect(Interview |> Repo.get(interview.id)) |> to(be(interview))
      expect(InterviewPanelist |> Repo.get(interview_panelist.id)) |> to(be(interview_panelist))
    end

    it "should update the candidate and not delete the successive and past interviews and panelists if the update is for not closing the pipeline" do
      candidate = create(:candidate)
      interview1 = create(:interview, %{candidate_id: candidate.id, start_time: Date.now |> Date.shift(days: 1)})
      interview2 = create(:interview, %{candidate_id: candidate.id, start_time: Date.now |> Date.shift(days: -1)})
      interview_panelist1 = create(:interview_panelist, interview_id: interview1.id)
      interview_panelist2 = create(:interview_panelist, interview_id: interview2.id)
      pipeline_status = create(:pipeline_status)
      response = put conn_with_dummy_authorization(), "/candidates/#{candidate.id}", %{"candidate" => %{"pipeline_status_id" => pipeline_status.id}}

      updated_candidate = Map.merge(candidate, %{pipeline_status_id: pipeline_status.id})
      response |> should(have_http_status(200))
      expect(response.assigns.candidate) |> to(be(updated_candidate))
      expect(Interview |> Repo.get(interview1.id)) |> to(be(interview1))
      expect(Interview |> Repo.get(interview2.id)) |> to(be(interview2))
      expect(InterviewPanelist |> Repo.get(interview_panelist1.id)) |> to(be(interview_panelist1))
      expect(InterviewPanelist |> Repo.get(interview_panelist2.id)) |> to(be(interview_panelist2))
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

        response = post conn_with_dummy_authorization(), "/candidates", %{"candidate" => post_parameters}

        expect(response.status) |> to(be(201))
        inserted_candidate = Repo.one(from c in Candidate, where: ilike(c.first_name, ^"%#{candidate_params.first_name}%"), preload: [:candidate_skills, :interviews])
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

        response = post conn_with_dummy_authorization(), "/candidates", %{"candidate" => Map.merge(build(:skill_ids), build(:interview_rounds))}

        expect(response.status) |> to(be(422))
        new_candidate_count = get_candidate_count
        expect(new_candidate_count) |> to(be(orig_candidate_count))
      end
    end

    context "with no POST params" do
      it "should return 400(Bad Request)" do
        orig_candidate_count = get_candidate_count

        response = post conn_with_dummy_authorization(), "/candidates", %{"candidate" => %{}}
        expect(response.status) |> to(be(422))
        new_candidate_count = get_candidate_count
        expect(new_candidate_count) |> to(be(orig_candidate_count))
      end
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
