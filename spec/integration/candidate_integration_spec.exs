defmodule RecruitxBackend.CandidateIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.CandidateController

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.TimexHelper

  describe "get /candidates" do
    before do:  Repo.delete_all(Candidate)

    it "should return a list of candidates" do
      interview1 = insert(:interview, start_time: TimexHelper.utc_now())
      interview2 = insert(:interview, start_time: TimexHelper.utc_now() |> TimexHelper.add(1, :hours))
      candidate1 = Candidate |> Repo.get(interview1.candidate_id)
      candidate2 = Candidate |> Repo.get(interview2.candidate_id)

      response = get conn_with_dummy_authorization(), "/candidates"

      expect(response.status) |> to(be(200))
      expect(response.assigns.candidates.total_pages) |> to(eq(1))
      expect(response.assigns.candidates.entries) |> to(eq([candidate1, candidate2]))
    end

    it "should return a candidates with and without interviews " do
      interview1 = insert(:interview, start_time: TimexHelper.utc_now())
      candidate1 = Candidate |> Repo.get(interview1.candidate_id)
      candidate2 = insert(:candidate)

      response = get conn_with_dummy_authorization(), "/candidates"

      expect(response.status) |> to(be(200))
      expect(response.assigns.candidates.total_pages) |> to(eq(1))
      expect(Enum.at(response.assigns.candidates.entries, 0).id) |> to(be(candidate1.id))
      expect(Enum.at(response.assigns.candidates.entries, 1).id) |> to(be(candidate2.id))
    end
  end

  describe "update /candidates/:id" do
    it "should update and return the candidate" do
      candidate = insert(:candidate)

      response = put conn_with_dummy_authorization(), "/candidates/#{candidate.id}", %{"candidate" => %{first_name: "test"}}

      updated_candidate = Map.merge(candidate, %{first_name: "test"})
      response |> should(have_http_status(200))
      expect(response.assigns.candidate.first_name) |> to(be(updated_candidate.first_name))
    end

    it "should not update and return errors when invalid change" do
      candidate = insert(:candidate)

      response = put conn_with_dummy_authorization(), "/candidates/#{candidate.id}", %{"candidate" => %{first_name: "test1"}}

      response |> should(have_http_status(:unprocessable_entity))
      expect(response.assigns.changeset.errors) |> to(be([first_name: {"has invalid format", [validation: :format]}]))
      expect((Candidate |> Repo.get(candidate.id)).id) |> to(be(candidate.id))
    end

    it "should return 404 when candidate is not found" do
      response = put conn_with_dummy_authorization(), "/candidates/0", %{"candidate" => %{first_name: "test"}}

      response |> should(have_http_status(:not_found))
    end

    it "should update the candidate and delete the successive interviews and panelists if the update is for closing the pipeline" do
      candidate = insert(:candidate)
      interview = insert(:interview, %{candidate: candidate, start_time: TimexHelper.utc_now() |> TimexHelper.add(1, :days)})
      interview_panelist = insert(:interview_panelist, interview: interview)
      closed_pipeline_status_id = PipelineStatus.retrieve_by_name(PipelineStatus.closed).id

      response = put conn_with_dummy_authorization(), "/candidates/#{candidate.id}", %{"candidate" => %{"pipeline_status_id" => closed_pipeline_status_id}}

      created_candidate = Map.merge(candidate, %{pipeline_status_id: closed_pipeline_status_id})
      response |> should(have_http_status(200))
      %{"id": updated_candidate_id, "pipeline_status_id": updated_pipeline_status_id} = response.assigns.candidate;
      expect(updated_candidate_id) |> to(be(created_candidate.id))
      expect(updated_pipeline_status_id) |> to(be(created_candidate.pipeline_status_id))
      expect(Interview |> Repo.get(interview.id)) |> to(be_nil())
      expect(InterviewPanelist |> Repo.get(interview_panelist.id)) |> to(be_nil())
    end

    it "should update the candidate and delete previous interviews and panelists if the update is for closing the pipeline and if interview_status_id is nil" do
      candidate = insert(:candidate)
      interview = insert(:interview, candidate: candidate, start_time: TimexHelper.utc_now() |> TimexHelper.add(-1, :days))
      insert(:interview_panelist, interview: interview)
      closed_pipeline_status_id = PipelineStatus.retrieve_by_name(PipelineStatus.closed).id

      response = put conn_with_dummy_authorization(), "/candidates/#{candidate.id}", %{"candidate" => %{"pipeline_status_id" => closed_pipeline_status_id}}

      created_candidate = Map.merge(candidate, %{pipeline_status_id: closed_pipeline_status_id})
      response |> should(have_http_status(200))
      %{"id": updated_candidate_id, "pipeline_status_id": updated_pipeline_status_id} = response.assigns.candidate;
      expect(updated_candidate_id) |> to(be(created_candidate.id))
      expect(updated_pipeline_status_id) |> to(be(created_candidate.pipeline_status_id))
      expect(Interview |> Repo.get(interview.id)) |> to(be(nil))
    end

    it "should update the candidate and not delete previous interviews and panelists if the update is for closing the pipeline and if interview_status_id is not nil" do
      candidate = insert(:candidate)
      interview = insert(:interview, candidate: candidate, start_time: TimexHelper.utc_now() |> TimexHelper.add(-1, :days), interview_status_id: 1)
      interview_panelist = insert(:interview_panelist, interview: interview)
      closed_pipeline_status_id = PipelineStatus.retrieve_by_name(PipelineStatus.closed).id

      response = put conn_with_dummy_authorization(), "/candidates/#{candidate.id}", %{"candidate" => %{"pipeline_status_id" => closed_pipeline_status_id}}

      created_candidate = Map.merge(candidate, %{pipeline_status_id: closed_pipeline_status_id})
      response |> should(have_http_status(200))
      %{"id": updated_candidate_id, "pipeline_status_id": updated_pipeline_status_id} = response.assigns.candidate;
      expect(updated_candidate_id) |> to(be(created_candidate.id))
      expect(updated_pipeline_status_id) |> to(be(created_candidate.pipeline_status_id))
      expect((Interview |> Repo.get(interview.id)).id) |> to(be(interview.id))
      expect((InterviewPanelist |> Repo.get(interview_panelist.id)).id) |> to(be(interview_panelist.id))
    end

    it "should update the candidate and not delete the successive and past interviews and panelists if the update is for not closing the pipeline" do
      candidate = insert(:candidate)
      interview1 = insert(:interview, candidate: candidate, start_time: TimexHelper.utc_now() |> TimexHelper.add(1, :days))
      interview2 = insert(:interview, candidate: candidate, start_time: TimexHelper.utc_now() |> TimexHelper.add(-1, :days))
      interview_panelist1 = insert(:interview_panelist, interview: interview1)
      interview_panelist2 = insert(:interview_panelist, interview: interview2)
      pipeline_status = insert(:pipeline_status)
      response = put conn_with_dummy_authorization(), "/candidates/#{candidate.id}", %{"candidate" => %{"pipeline_status_id" => pipeline_status.id}}

      created_candidate = Map.merge(candidate, %{pipeline_status_id: pipeline_status.id})
      response |> should(have_http_status(200))
      %{"id": updated_candidate_id, "pipeline_status_id": updated_pipeline_status_id} = response.assigns.candidate;
      expect(updated_candidate_id) |> to(be(created_candidate.id))
      expect(updated_pipeline_status_id) |> to(be(created_candidate.pipeline_status_id))
      expect((Interview |> Repo.get(interview1.id)).id) |> to(be(interview1.id))
      expect((Interview |> Repo.get(interview2.id)).id) |> to(be(interview2.id))
      expect((InterviewPanelist |> Repo.get(interview_panelist1.id)).id) |> to(be(interview_panelist1.id))
      expect((InterviewPanelist |> Repo.get(interview_panelist2.id)).id) |> to(be(interview_panelist2.id))
    end
  end

  describe "POST /candidates" do
    context "with valid params" do
      it "should create a new candidate and insert corresponding skill, interview round in the db" do
        orig_candidate_count = Candidate.count
        post_skill_params = build(:skill_ids)
        candidate_params = params_with_assocs(:candidate, experience: 6.21)
        interview_round_params = build(:interview_rounds)
        post_parameters = Map.merge(candidate_params, Map.merge(post_skill_params, interview_round_params))

        response = post conn_with_dummy_authorization(), "/candidates", %{"candidate" => post_parameters}

        expect(response.status) |> to(be(201))
        inserted_candidate = Repo.one(from c in Candidate, where: ilike(c.first_name, ^"%#{candidate_params.first_name}%"), preload: [:candidate_skills, :interviews])
        List.keyfind(response.resp_headers, "location", 0) |> should(be({"location", "/candidates/#{inserted_candidate.id}"}))

        new_candidate_count = Candidate.count
        expect(new_candidate_count) |> to(be(orig_candidate_count + 1))
        assertInsertedSkillIdsFor(inserted_candidate, post_skill_params.skill_ids)
        assertInsertedInterviewRoundsFor(inserted_candidate, interview_round_params)
      end
    end

    context "with invalid params" do
      it "should not create a new candidate in the db" do
        orig_candidate_count = Candidate.count

        response = post conn_with_dummy_authorization(), "/candidates", %{"candidate" => Map.merge(build(:skill_ids), build(:interview_rounds))}

        expect(response.status) |> to(be(422))
        new_candidate_count = Candidate.count
        expect(new_candidate_count) |> to(be(orig_candidate_count))
      end

      it "should not create a new candidate in the db if skill is not correct" do
        orig_candidate_count = Candidate.count
        post_skill_params = %{skill_ids: [1.23]}
        candidate_params = params_with_assocs(:candidate, experience: 6.21)
        interview_round_params = build(:interview_rounds)
        post_parameters = Map.merge(candidate_params, Map.merge(post_skill_params, interview_round_params))

        response = post conn_with_dummy_authorization(), "/candidates", %{"candidate" => post_parameters}

        expect(response.status) |> to(be(422))
        new_candidate_count = Candidate.count
        expect(new_candidate_count) |> to(be(orig_candidate_count))
      end
    end

    context "with no POST params" do
      it "should return 400(Bad Request)" do
        orig_candidate_count = Candidate.count

        response = post conn_with_dummy_authorization(), "/candidates", %{"candidate" => %{}}
        expect(response.status) |> to(be(422))
        new_candidate_count = Candidate.count
        expect(new_candidate_count) |> to(be(orig_candidate_count))
      end
    end

    defp get_candidate_skill_ids_for(candidate) do
      for skill <- candidate.candidate_skills, do: skill.skill_id
    end

    defp assertInsertedSkillIdsFor(inserted_candidate, skill_ids) do
      candidate_skills = inserted_candidate |> get_candidate_skill_ids_for |> Enum.sort
      unique_skill_ids = skill_ids |> Enum.uniq |> Enum.sort
      expect(candidate_skills) |> to(be(unique_skill_ids))
    end

    defp assertInsertedInterviewRoundsFor(candidate, interview_rounds_params) do
      interview_to_insert = interview_rounds_params[:interview_rounds]
      interview_inserted = candidate.interviews

      for index <- 0..(Kernel.length(interview_to_insert) - 1) do
        %{"interview_type_id" => id, "start_time" => date_time} = Enum.at(interview_to_insert, index)
        interview_round = Enum.at(interview_inserted, index)

        expect(interview_round.interview_type_id) |> to(be(id))
        expect(Timex.diff(interview_round.start_time, date_time, :seconds)) |> to(be(0))
      end
    end
  end
end
