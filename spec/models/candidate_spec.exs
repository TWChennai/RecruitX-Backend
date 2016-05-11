defmodule RecruitxBackend.CandidateSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Candidate

  import Ecto.Query

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewStatus
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.Skill
  alias Timex.Date

  let :valid_attrs, do: fields_for(:candidate, other_skills: "other skills", role_id: create(:role).id, pipeline_status_id: create(:pipeline_status).id)
  let :invalid_attrs, do: %{}
  let :previous_week, do: RecruitxBackend.Timer.get_previous_week

  context "valid changeset" do
    subject do: Candidate.changeset(%Candidate{}, valid_attrs)

    it do: should be_valid

    it "should be valid when additional information is not given" do
      candidate_with_no_additional_skills = Map.delete(valid_attrs, :other_skills)
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_additional_skills)

      expect(changeset) |> to(be_valid)
    end

    it "should be valid when experience is 0" do
      candidate_with_no_experience = Map.merge(valid_attrs, %{experience: Decimal.new(0)})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_experience)

      expect(changeset) |> to(be_valid)
    end

    it "should be valid when pipeline_status_id is not given and is replaced by default value" do
      candidate_with_no_pipeline_status = Map.delete(valid_attrs, :pipeline_status_id)
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_pipeline_status)

      expect(changeset) |> to(be_valid)
    end

    it "should be valid when pipeline_status_id is nil and is replaced by default value" do
      candidate_with_no_pipeline_status = Map.merge(valid_attrs, %{pipeline_status_id: nil})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_pipeline_status)

      expect(changeset) |> to(be_valid)
    end

    it "should be valid with the given pipeline_status_id" do
      ps = create(:pipeline_status)
      changeset = Candidate.changeset(%Candidate{}, Map.merge(valid_attrs, %{pipeline_status_id: ps.id}))

      expect(changeset.changes.pipeline_status_id) |> to(be(ps.id))
    end
  end

  context "invalid changeset" do
    subject do: Candidate.changeset(%Candidate{}, invalid_attrs)

    it do: should_not be_valid
    it do: should have_errors(first_name: "can't be blank", last_name: "can't be blank", role_id: "can't be blank", experience: "can't be blank")

    it "should be invalid when first_name is an empty string" do
      candidate_with_empty_name = Map.merge(valid_attrs, %{first_name: ""})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_empty_name)

      expect(changeset) |> to(have_errors(first_name: {"should be at least %{count} character(s)", [count: 1]}))
    end

    it "should be invalid when first_name is nil" do
      candidate_with_nil_name = Map.merge(valid_attrs, %{first_name: nil})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_nil_name)

      expect(changeset) |> to(have_errors([first_name: "can't be blank"]))
    end

    it "should be invalid when first_name is a blank string" do
      candidte_with_blank_name = Map.merge(valid_attrs, %{first_name: "  "})
      changeset = Candidate.changeset(%Candidate{}, candidte_with_blank_name)

      expect(changeset) |> to(have_errors([first_name: "has invalid format"]))
    end

    it "should be invalid when first_name is only numbers" do
      candidate_with_numbers_name = Map.merge(valid_attrs, %{first_name: "678"})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_numbers_name)

      expect(changeset) |> to(have_errors([first_name: "has invalid format"]))
    end

    it "should be invalid when first_name starts with space" do
      candidate_starting_with_space_name = Map.merge(valid_attrs, %{first_name: " space"})
      changeset = Candidate.changeset(%Candidate{}, candidate_starting_with_space_name)

      expect(changeset) |> to(have_errors([first_name: "has invalid format"]))
    end

    it "should be invalid when last_name is an empty string" do
      candidate_with_empty_name = Map.merge(valid_attrs, %{last_name: ""})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_empty_name)

      expect(changeset) |> to(have_errors(last_name: {"should be at least %{count} character(s)", [count: 1]}))
    end

    it "should be invalid when last_name is nil" do
      candidate_with_nil_name = Map.merge(valid_attrs, %{last_name: nil})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_nil_name)

      expect(changeset) |> to(have_errors([last_name: "can't be blank"]))
    end

    it "should be invalid when last_name is a blank string" do
      candidte_with_blank_name = Map.merge(valid_attrs, %{last_name: "  "})
      changeset = Candidate.changeset(%Candidate{}, candidte_with_blank_name)

      expect(changeset) |> to(have_errors([last_name: "has invalid format"]))
    end

    it "should be invalid when last_name is only numbers" do
      candidate_with_numbers_name = Map.merge(valid_attrs, %{last_name: "678"})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_numbers_name)

      expect(changeset) |> to(have_errors([last_name: "has invalid format"]))
    end

    it "should be invalid when last_name starts with space" do
      candidate_starting_with_space_name = Map.merge(valid_attrs, %{last_name: " space"})
      changeset = Candidate.changeset(%Candidate{}, candidate_starting_with_space_name)

      expect(changeset) |> to(have_errors([last_name: "has invalid format"]))
    end

    it "should be invalid when experience is nil" do
      candidate_with_nil_experience = Map.merge(valid_attrs, %{experience: nil})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_nil_experience)

      expect(changeset) |> to(have_errors(experience: "can't be blank"))
    end

    it "should be invalid when experience is an empty string" do
      candidate_with_empty_experience = Map.merge(valid_attrs, %{experience: ""})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_empty_experience)

      expect(changeset) |> to(have_errors(experience: "is invalid"))
    end

    it "should be invalid when experience is negative" do
      candidate_with_negative_experience = Map.merge(valid_attrs, %{experience: Decimal.new(-4)})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_negative_experience)

      expect(changeset) |> to(have_errors(experience: {"must be in the range 0-100", [count: Decimal.new(0)]}))
    end

    it "should be invalid when experience is more than or equal to 100" do
      candidate_with_invalid_experience = Map.merge(valid_attrs, %{experience: Decimal.new(100)})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_invalid_experience)

      expect(changeset) |> to(have_errors(experience: {"must be in the range 0-100", [count: Decimal.new(100)]}))
    end

    it "should be invalid when no experience is given" do
      candidate_with_no_experience = Map.delete(valid_attrs, :experience)
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_experience)

      expect(changeset) |> to(have_errors(experience: "can't be blank"))
    end
  end

  context "on delete" do
    it "should not raise an exception when it has foreign key reference in other tables" do
      candidate = create(:candidate)
      create(:interview, candidate_id: candidate.id)

      delete = fn -> Repo.delete!(candidate) end

      expect(delete).to_not raise_exception(Ecto.ConstraintError)
    end

    it "should not raise an exception when it has no foreign key references in other tables" do
      candidate = create(:candidate)

      delete = fn ->  Repo.delete!(candidate) end

      expect(delete).to_not raise_exception(Ecto.ConstraintError)
    end
  end

  context "query" do
    it "should return candidates in FIFO order" do
      Repo.delete_all(Candidate)

      interview1 = create(:interview, interview_type_id: 1, start_time: Date.now)
      interview2 = create(:interview, interview_type_id: 1, start_time: Date.now |> Date.shift(hours: 1))
      candidate_id1 = interview1.candidate_id
      candidate_id2 = interview2.candidate_id

      [result1, result2] = Candidate.get_candidates_in_fifo_order |> Repo.all

      expect([result1.id, result2.id]) |> to(be([candidate_id1, candidate_id2]))
    end

    it "should return candidates without interviews last in FIFO order" do
      Repo.delete_all(Candidate)
      candidate_without_interview = create(:candidate)

      interview = create(:interview, interview_type_id: 1, start_time: Date.now)
      candidate_with_interview_id = interview.candidate_id

      [result1, result2] = Candidate.get_candidates_in_fifo_order |> Repo.all

      expect([result1.id, result2.id]) |> to(be([candidate_with_interview_id, candidate_without_interview.id]))
    end
  end

  context "updateCandidateStatusAsPass" do
    it "should update candidate status as Pass" do
      interview = create(:interview, interview_type_id: 1, start_time: Date.now)
      candidate_id = interview.candidate_id
      pass_id = PipelineStatus.retrieve_by_name(PipelineStatus.pass).id

      Candidate.updateCandidateStatusAsPass(candidate_id)

      updated_candidate = Candidate |> Repo.get(candidate_id)

      expect(updated_candidate.pipeline_status_id) |> to(be(pass_id))
    end
  end

  context "get formattted skills" do
    let :candidate, do: create(:candidate, other_skills: "Other Skills")
    before do
      create(:candidate_skill, skill_id: create(:skill, name: "Skill 1").id, candidate_id: candidate.id)
      create(:candidate_skill, skill_id: create(:skill, name: "Skill 2").id, candidate_id: candidate.id)
    end

    it "should contain concatenated skills for the candidate in the result" do
      formatted_skills = Candidate
        |> preload([:skills])
        |> Repo.get(candidate.id)
        |> Candidate.get_formatted_skills

      expect(formatted_skills) |> to(have("Skill 1"))
      expect(formatted_skills) |> to(have("Skill 2"))
    end

    it "should append other skills for the candidate in the result" do
      create(:candidate_skill, skill_id: Skill.other_skill_id, candidate_id: candidate.id)
      formatted_skills = Candidate
        |> preload([:skills])
        |> Repo.get(candidate.id)
        |> Candidate.get_formatted_skills

      expect(formatted_skills) |> to(have("Skill 1"))
      expect(formatted_skills) |> to(have("Skill 2"))
      expect(formatted_skills) |> to(have("Other Skills"))
    end
  end

  context "get formatted interviews" do
    let :candidate, do: create(:candidate)
    let :interview_type_one, do: create(:interview_type)
    let :interview_type_two, do: create(:interview_type)

    before do
      create(:interview, candidate_id: candidate.id, interview_type_id: interview_type_one.id)
      create(:interview, candidate_id: candidate.id, interview_type_id: interview_type_two.id)
    end

    it "should return list of formatted interviews" do
      formatted_interviews = Candidate
        |> preload([:interviews, interviews: [:interview_type]])
        |> Repo.get(candidate.id)
        |> Candidate.get_formatted_interviews

      expect(Enum.count(formatted_interviews)) |> to(be(2))
    end
  end

  context "get formatted interviews with result" do
    let :candidate, do: create(:candidate)
    let :interview_type_one, do: create(:interview_type)
    let :interview_type_two, do: create(:interview_type)

    before do
      create(:interview, candidate_id: candidate.id, interview_type_id: interview_type_one.id)
      create(:interview, candidate_id: candidate.id, interview_type_id: interview_type_two.id)
    end

    it "should call formatted interviews with result and panelists for all interviews" do
      allow Interview |> to(accept(:format_with_result_and_panelist, fn(_) -> ""  end))
      query = Interview |> preload([:interview_panelist, :interview_status, :interview_type])
      candidates = Candidate |> preload([:role, interviews: ^query]) |>  where([i], i.id == ^candidate.id) |> Repo.one
      [interview1, interview2] = candidates.interviews

      Candidate.get_formatted_interviews_with_result(candidates)

      expect Interview |> to(accepted :format_with_result_and_panelist, [interview1])
      expect Interview |> to(accepted :format_with_result_and_panelist, [interview2])
    end
  end


  context "get rounded experience" do
    it "should return experience in single precision" do
      candidate = create(:candidate, experience: Decimal.new(4.67))

      actual_experience = Candidate.get_rounded_experience(candidate)

      expect(actual_experience) |> to(be("4.7"))
    end

    it "should not return experience mantissa-exponent format" do
      candidate = create(:candidate, experience: Decimal.new(10.00))

      actual_experience = Candidate.get_rounded_experience(candidate)

      expect(actual_experience) |> to(be("10.0"))
    end
  end

  context "get candidate by id" do
    it "should return empty array when given an non-existing candidate id" do

      candidate = Candidate.get_candidate_by_id(1000) |> Repo.one
      expect(candidate) |> to(be_nil)
    end

    it "should return candidate details when given an existing candidate id" do
      candidate = create(:candidate)
      create(:interview, candidate_id: candidate.id)

      actual_candidate = Candidate.get_candidate_by_id(candidate.id) |> Repo.one

      expect(actual_candidate.id) |> to(be(candidate.id))
      expect(Enum.count(actual_candidate.interviews)) |> to(be(1))
    end
  end

  context "get the total no. of candidates in progress" do
    before do
      Repo.delete_all(Candidate)
    end

    it "should return the total no. of candidates in progress" do
      in_progress_pipeline = PipelineStatus.retrieve_by_name(PipelineStatus.in_progress)
      closed_pipeline = PipelineStatus.retrieve_by_name(PipelineStatus.closed)
      in_progress_candidate = create(:candidate, other_skills: "Other Skills", pipeline_status_id: in_progress_pipeline.id)
      create(:candidate, other_skills: "Other Skills", pipeline_status_id: closed_pipeline.id)        # closed candidate

      expect(Candidate.get_total_no_of_candidates_in_progress(in_progress_candidate.role_id)) |> to(be(1))
    end
  end

  context "get all candidates pursued after pipeline closure" do
    before do
      Repo.delete_all(Candidate)
    end

    let :role1, do: create(:role, role_id: 1 ,name: "Role1")
    let :interview_type1, do: create(:interview_type, name: "interview_type1")
    let :progress_pipeline_status, do: PipelineStatus.retrieve_by_name(PipelineStatus.in_progress)
    let :pass_pipeline_status, do: PipelineStatus.retrieve_by_name(PipelineStatus.pass)
    let :closed_pipeline_status, do: PipelineStatus.retrieve_by_name(PipelineStatus.closed)

    it "should return candidate who is pursue in all interviews and pipeline is closed" do
      create(:role_interview_type, role_id: role1.id,interview_type_id: interview_type1.id)
      pursue = InterviewStatus.retrieve_by_name(InterviewStatus.pursue)
      candidate1 = create(:candidate, pipeline_status_id: closed_pipeline_status.id, role_id: role1.id, pipeline_closure_time: get_start_of_current_week)
      create(:interview, start_time: get_start_of_current_week, interview_type_id: interview_type1.id, interview_status_id: pursue.id, candidate_id: candidate1.id)

      {[candidates], _} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(previous_week, role1.id)

      expect(candidates) |> to(be(candidate1))
    end

    it "should NOT return candidate who is pursue in all interviews and pipeline is NOT closed" do
      create(:role_interview_type, role_id: role1.id,interview_type_id: interview_type1.id)
      pursue = InterviewStatus.retrieve_by_name(InterviewStatus.pursue)
      candidate1 = create(:candidate, role_id: role1.id, pipeline_status_id: progress_pipeline_status.id)
      create(:interview, interview_type_id: interview_type1.id, interview_status_id: pursue.id, candidate_id: candidate1.id)

      {candidates, _} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(previous_week, role1.id)

      expect(candidates) |> to(be([]))
    end

    it "should NOT return candidate who is pass in one interview after pipeline is closed" do
      create(:role_interview_type, role_id: role1.id,interview_type_id: interview_type1.id)
      pass = InterviewStatus.retrieve_by_name(InterviewStatus.pass)
      candidate1 = create(:candidate, role_id: role1.id, pipeline_status_id: closed_pipeline_status.id, pipeline_closure_time: Date.now |> Date.shift(days: -2))
      create(:interview, interview_type_id: interview_type1.id, interview_status_id: pass.id, candidate_id: candidate1.id)

      {candidates, _} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(previous_week, role1.id)

      expect(candidates) |> to(be([]))
    end

    it "should NOT return candidate who is not completed all interviews after pipeline is closed" do
      create(:role_interview_type, role_id: role1.id,interview_type_id: interview_type1.id)
      create(:candidate, role_id: role1.id, pipeline_status_id: closed_pipeline_status.id, pipeline_closure_time: Date.now |> Date.shift(days: -2))

      {candidates, _} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(previous_week, role1.id)

      expect(candidates) |> to(be([]))
    end
  end

  context "get all candidates rejected after pipeline closure" do
    before do
      Repo.delete_all(Candidate)
    end

    let :role1, do: create(:role, role_id: 1 ,name: "Role1")
    let :interview_type1, do: create(:interview_type, name: "interview_type1")
    let :progress_pipeline_status, do: PipelineStatus.retrieve_by_name(PipelineStatus.in_progress)
    let :pass_pipeline_status, do: PipelineStatus.retrieve_by_name(PipelineStatus.pass)
    let :closed_pipeline_status, do: PipelineStatus.retrieve_by_name(PipelineStatus.closed)

    it "should NOT return candidate who is pursue in all interviews and pipeline is closed" do
      create(:role_interview_type, role_id: role1.id,interview_type_id: interview_type1.id)
      pursue = InterviewStatus.retrieve_by_name(InterviewStatus.pursue)
      candidate1 = create(:candidate, pipeline_status_id: closed_pipeline_status.id, role_id: role1.id, pipeline_closure_time: Date.now |> Date.shift(days: -1))
      create(:interview, start_time: get_start_of_current_week , interview_type_id: interview_type1.id, interview_status_id: pursue.id, candidate_id: candidate1.id)

      {_, candidates}= Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(previous_week, role1.id)

      expect(candidates) |> to(be([]))
    end

    it "should NOT return candidate whose pipeline is NOT closed" do
      create(:role_interview_type, role_id: role1.id,interview_type_id: interview_type1.id)
      pursue = InterviewStatus.retrieve_by_name(InterviewStatus.pursue)
      candidate1 = create(:candidate, role_id: role1.id, pipeline_status_id: progress_pipeline_status.id)
      create(:interview, interview_type_id: interview_type1.id, interview_status_id: pursue.id, candidate_id: candidate1.id)

      {_, candidates} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(previous_week, role1.id)

      expect(candidates) |> to(be([]))
    end

    it "should return candidate who is pass in one interview and pipeline is closed" do
      create(:role_interview_type, role_id: role1.id,interview_type_id: interview_type1.id)
      pass = InterviewStatus.retrieve_by_name(InterviewStatus.pass)
      candidate1 = create(:candidate, role_id: role1.id, pipeline_status_id: closed_pipeline_status.id, pipeline_closure_time: get_start_of_current_week)
      create(:interview, interview_type_id: interview_type1.id, interview_status_id: pass.id, candidate_id: candidate1.id)

      {_, [candidates]} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(previous_week, role1.id)

      expect(candidates) |> to(be(candidate1))
    end

    it "should return candidate who is not completed all interviews after pipeline is closed" do
      create(:role_interview_type, role_id: role1.id,interview_type_id: interview_type1.id)
      candidate1 = create(:candidate, role_id: role1.id, pipeline_status_id: closed_pipeline_status.id, pipeline_closure_time: get_start_of_current_week)

      {_, [candidates]} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(previous_week, role1.id)

      expect(candidates) |> to(be(candidate1))
    end
  end

  context "get_no_of_pass_candidates_within_range" do
    before do
      Repo.delete_all(Candidate)
    end

    let :role1, do: create(:role, role_id: 1 ,name: "Role1")
    let :interview_type1, do: create(:interview_type, name: "interview_type1")

    it "should return 1 when a candidate is pass in an interview within range and pipeline is pass" do
      pass_pipeline_status = PipelineStatus.retrieve_by_name(PipelineStatus.pass)
      pass = InterviewStatus.retrieve_by_name(InterviewStatus.pass)
      candidate1 = create(:candidate, pipeline_status_id: pass_pipeline_status.id, role_id: role1.id)
      create(:interview, start_time: get_start_of_current_week, interview_type_id: interview_type1.id, interview_status_id: pass.id, candidate_id: candidate1.id)

      candidates_count = Candidate.get_no_of_pass_candidates_within_range(previous_week, role1.id)

      expect(candidates_count) |> to(be(1))
    end

    it "should return 0 when candidate is pass in an interview NOT IN RANGE and pipeline is pass" do
      pass_pipeline_status = PipelineStatus.retrieve_by_name(PipelineStatus.pass)
      pass = InterviewStatus.retrieve_by_name(InterviewStatus.pass)
      candidate1 = create(:candidate, pipeline_status_id: pass_pipeline_status.id, role_id: role1.id)
      create(:interview, start_time: Date.now |> Date.end_of_week |> Date.shift(days: +1), interview_type_id: interview_type1.id, interview_status_id: pass.id, candidate_id: candidate1.id)

      candidates_count = Candidate.get_no_of_pass_candidates_within_range(previous_week, role1.id)

      expect(candidates_count) |> to(be(0))
    end

    it "should return 0 when candidate is pursue in an interview within range" do
      progress_pipeline_status = PipelineStatus.retrieve_by_name(PipelineStatus.in_progress)
      pursue = InterviewStatus.retrieve_by_name(InterviewStatus.pursue)
      candidate1 = create(:candidate, pipeline_status_id: progress_pipeline_status.id, role_id: role1.id)
      create(:interview, start_time: get_start_of_current_week, interview_type_id: interview_type1.id, interview_status_id: pursue.id, candidate_id: candidate1.id)

      candidates_count = Candidate.get_no_of_pass_candidates_within_range(previous_week, role1.id)

      expect(candidates_count) |> to(be(0))
    end
  end

  context "get_candidates_scheduled_for_date_and_interview_round" do
    before do
      Repo.delete_all(Interview)
    end

    let :interview_type, do: create(:interview_type, priority: 2)

    it "should return empty array when there are no interviews" do
      result = Candidate.get_candidates_scheduled_for_date_and_interview_round(get_start_of_next_week, interview_type.id) |> Repo.all

      expect(result) |> to(be([]))
    end

    it "should return empty array when there are no interviews with lesser priority on the day" do
      create(:interview, start_time: get_start_of_next_week , interview_type_id: create(:interview_type, priority: 2).id)
      result = Candidate.get_candidates_scheduled_for_date_and_interview_round(get_start_of_next_week, interview_type.id) |> Repo.all

      expect(result) |> to(be([]))
    end

    it "should return empty array when there are no interviews on the day" do
      create(:interview, start_time: get_start_of_next_week |> Date.shift(days: 1) , interview_type_id: create(:interview_type, priority: 1).id)
      create(:interview, start_time: get_start_of_next_week |> Date.shift(days: -1) , interview_type_id: create(:interview_type, priority: 1).id)
      result = Candidate.get_candidates_scheduled_for_date_and_interview_round(get_start_of_next_week, interview_type.id) |> Repo.all

      expect(result) |> to(be([]))
    end

    it "should return empty array when there is an interviews on the day with lesser priority" do
      interview = create(:interview, start_time: get_start_of_next_week , interview_type_id: create(:interview_type, priority: 1).id)

      [result] = Candidate.get_candidates_scheduled_for_date_and_interview_round(get_start_of_next_week |> Date.shift(hours: 5), interview_type.id) |> Repo.all

      expect([result]) |> to_not(be([]))
      expect(result.id) |> to(be(interview.candidate_id))
    end
  end

  context "get_unique_skills_formatted" do
    before do
      Repo.delete_all(Candidate)
    end

    it "should concat all skills of given candidates" do
      candidate1 = create(:candidate)
      candidate2 = create(:candidate)
      candidate_excluded = create(:candidate)
      create(:candidate_skill, skill_id: create(:skill, name: "Skill 1").id, candidate_id: candidate1.id)
      create(:candidate_skill, skill_id: create(:skill, name: "Skill 2").id, candidate_id: candidate1.id)
      create(:candidate_skill, skill_id: create(:skill, name: "Skill 3").id, candidate_id: candidate_excluded.id)

      result = Candidate.get_unique_skills_formatted([candidate1.id, candidate2.id])

      expect(result) |> to(be("Skill 1/Skill 2"))
      expect(result) |> to_not(have("Skill 3"))
    end
  end


end
