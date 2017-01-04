defmodule RecruitxBackend.CandidateSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Candidate

  import Ecto.Query

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewStatus
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.Skill
  alias RecruitxBackend.Timer
  alias RecruitxBackend.TimexHelper

  let :valid_attrs, do: params_with_assocs(:candidate, other_skills: "other skills")
  let :invalid_attrs, do: %{}
  let :current_week, do: Timer.get_current_week_weekdays
  let :closed_pipeline_status, do: PipelineStatus.retrieve_by_name(PipelineStatus.closed)

  context "valid changeset" do
    subject do: Candidate.changeset(%Candidate{}, valid_attrs())

    it do: should be_valid()

    it "should be valid when additional information is not given" do
      candidate_with_no_additional_skills = Map.delete(valid_attrs(), :other_skills)
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_additional_skills)

      expect(changeset) |> to(be_valid())
    end

    it "should be valid when experience is 0" do
      candidate_with_no_experience = Map.merge(valid_attrs(), %{experience: Decimal.new(0)})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_experience)

      expect(changeset) |> to(be_valid())
    end

    it "should be valid when pipeline_status_id is not given and is replaced by default value" do
      candidate_with_no_pipeline_status = Map.delete(valid_attrs(), :pipeline_status_id)
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_pipeline_status)

      expect(changeset) |> to(be_valid())
    end

    it "should be valid when pipeline_status_id is nil and is replaced by default value" do
      candidate_with_no_pipeline_status = Map.merge(valid_attrs(), %{pipeline_status: nil})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_pipeline_status)

      expect(changeset) |> to(be_valid())
    end

    it "should be valid with the given pipeline_status_id" do
      ps = insert(:pipeline_status)
      changeset = Candidate.changeset(%Candidate{}, Map.merge(valid_attrs(), %{pipeline_status_id: ps.id}))

      expect(changeset) |> to(be_valid())
      expect(changeset.changes.pipeline_status_id) |> to(be(ps.id))
    end
  end

  context "invalid changeset" do
    subject do: Candidate.changeset(%Candidate{}, invalid_attrs())

    it do: should_not be_valid()
    it do: should have_errors(first_name: {"can't be blank", [validation: :required]}, last_name: {"can't be blank", [validation: :required]}, role_id: {"can't be blank", [validation: :required]}, experience: {"can't be blank", [validation: :required]})

    it "should be invalid when first_name is an empty string" do
      candidate_with_empty_name = Map.merge(valid_attrs(), %{first_name: ""})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_empty_name)

      expect(changeset) |> to(have_errors(first_name: {"can't be blank", [validation: :required]}))
    end

    it "should be invalid when first_name is nil" do
      candidate_with_nil_name = Map.merge(valid_attrs(), %{first_name: nil})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_nil_name)

      expect(changeset) |> to(have_errors([first_name: {"can't be blank", [validation: :required]}]))
    end

    it "should be invalid when first_name is a blank string" do
      candidte_with_blank_name = Map.merge(valid_attrs(), %{first_name: "  "})
      changeset = Candidate.changeset(%Candidate{}, candidte_with_blank_name)

      expect(changeset) |> to(have_errors([first_name: {"has invalid format", [validation: :format]}]))
    end

    it "should be invalid when first_name is only numbers" do
      candidate_with_numbers_name = Map.merge(valid_attrs(), %{first_name: "678"})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_numbers_name)

      expect(changeset) |> to(have_errors([first_name: {"has invalid format", [validation: :format]}]))
    end

    it "should be invalid when first_name starts with space" do
      candidate_starting_with_space_name = Map.merge(valid_attrs(), %{first_name: " space"})
      changeset = Candidate.changeset(%Candidate{}, candidate_starting_with_space_name)

      expect(changeset) |> to(have_errors([first_name: {"has invalid format", [validation: :format]}]))
    end

    it "should be invalid when last_name is an empty string" do
      candidate_with_empty_name = Map.merge(valid_attrs(), %{last_name: ""})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_empty_name)

      expect(changeset) |> to(have_errors(last_name: {"can't be blank", [validation: :required]}))
    end

    it "should be invalid when last_name is nil" do
      candidate_with_nil_name = Map.merge(valid_attrs(), %{last_name: nil})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_nil_name)

      expect(changeset) |> to(have_errors([last_name: {"can't be blank", [validation: :required]}]))
    end

    it "should be invalid when last_name is a blank string" do
      candidte_with_blank_name = Map.merge(valid_attrs(), %{last_name: "  "})
      changeset = Candidate.changeset(%Candidate{}, candidte_with_blank_name)

      expect(changeset) |> to(have_errors([last_name: {"has invalid format", [validation: :format]}]))
    end

    it "should be invalid when last_name is only numbers" do
      candidate_with_numbers_name = Map.merge(valid_attrs(), %{last_name: "678"})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_numbers_name)

      expect(changeset) |> to(have_errors([last_name: {"has invalid format", [validation: :format]}]))
    end

    it "should be invalid when last_name starts with space" do
      candidate_starting_with_space_name = Map.merge(valid_attrs(), %{last_name: " space"})
      changeset = Candidate.changeset(%Candidate{}, candidate_starting_with_space_name)

      expect(changeset) |> to(have_errors([last_name: {"has invalid format", [validation: :format]}]))
    end

    it "should be invalid when experience is nil" do
      candidate_with_nil_experience = Map.merge(valid_attrs(), %{experience: nil})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_nil_experience)

      expect(changeset) |> to(have_errors(experience: {"can't be blank", [validation: :required]}))
    end

    it "should be invalid when experience is an empty string" do
      candidate_with_empty_experience = Map.merge(valid_attrs(), %{experience: ""})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_empty_experience)

      expect(changeset) |> to(have_errors(experience: {"can't be blank", [validation: :required]}))
    end

    it "should be invalid when experience is negative" do
      candidate_with_negative_experience = Map.merge(valid_attrs(), %{experience: Decimal.new(-4)})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_negative_experience)

      expect(changeset) |> to(have_errors(experience: {"must be in the range 0-100", [validation: :number, number: Decimal.new(0)]}))
    end

    it "should be invalid when experience is more than or equal to 100" do
      candidate_with_invalid_experience = Map.merge(valid_attrs(), %{experience: Decimal.new(100)})
      changeset = Candidate.changeset(%Candidate{}, candidate_with_invalid_experience)

      expect(changeset) |> to(have_errors(experience: {"must be in the range 0-100", [validation: :number, number: Decimal.new(100)]}))
    end

    it "should be invalid when no experience is given" do
      candidate_with_no_experience = Map.delete(valid_attrs(), :experience)
      changeset = Candidate.changeset(%Candidate{}, candidate_with_no_experience)

      expect(changeset) |> to(have_errors(experience: {"can't be blank", [validation: :required]}))
    end
  end

  context "on delete" do
    it "should not raise an exception when it has foreign key reference in other tables" do
      candidate = insert(:candidate)
      insert(:interview, candidate: candidate)

      delete = fn -> Repo.delete!(candidate) end

      expect(delete).to_not raise_exception(Ecto.ConstraintError)
    end

    it "should not raise an exception when it has no foreign key references in other tables" do
      candidate = insert(:candidate)

      delete = fn ->  Repo.delete!(candidate) end

      expect(delete).to_not raise_exception(Ecto.ConstraintError)
    end
  end

  context "query" do
    before do: Repo.delete_all(Candidate)

    it "should return candidates in FIFO order" do
      interview1 = insert(:interview, start_time: TimexHelper.utc_now())
      interview2 = insert(:interview, start_time: TimexHelper.utc_now() |> TimexHelper.add(1, :hours))
      candidate_id1 = interview1.candidate_id
      candidate_id2 = interview2.candidate_id

      [result1, result2] = Candidate.get_candidates_in_fifo_order |> Repo.all

      expect([result1.id, result2.id]) |> to(be([candidate_id1, candidate_id2]))
    end

    it "should return candidates without interviews last in FIFO order" do
      closed_candidate = insert(:candidate, pipeline_status: closed_pipeline_status())

      interview = insert(:interview, start_time: TimexHelper.utc_now())
      candidate_with_interview_id = interview.candidate_id

      [result1, result2] = Candidate.get_candidates_in_fifo_order |> Repo.all

      expect([result1.id, result2.id]) |> to(be([candidate_with_interview_id, closed_candidate.id]))
    end

    it "should return candidates in FIFO order and with pipeline_status_id" do
      closed_candidate_interview = insert(:interview, start_time: TimexHelper.utc_now())
      in_progress_candidate_interview_starts_lately = insert(:interview, start_time: TimexHelper.utc_now() |> TimexHelper.add(1, :hours))
      in_progress_candidate_interview_starts_quickly = insert(:interview, start_time: TimexHelper.utc_now() |> TimexHelper.add(-1, :hours))
      candidate = (Repo.get(Candidate, closed_candidate_interview.candidate_id) |> Repo.preload(:pipeline_status))
      Ecto.Changeset.change(candidate) |> Ecto.Changeset.put_change(:pipeline_status_id, closed_pipeline_status().id) |> Repo.update

      [result1, result2, result3] = Candidate.get_candidates_in_fifo_order |> Repo.all

      expect([result1.id, result2.id, result3.id]) |> to(be([in_progress_candidate_interview_starts_quickly.candidate_id,
                                                              in_progress_candidate_interview_starts_lately.candidate_id,
                                                              closed_candidate_interview.candidate_id]))
    end
  end

  context "updateCandidateStatusAsPass" do
    it "should update candidate status as Pass" do
      interview = insert(:interview, start_time: TimexHelper.utc_now())
      candidate_id = interview.candidate_id
      pass_id = PipelineStatus.retrieve_by_name(PipelineStatus.pass).id

      Candidate.updateCandidateStatusAsPass(candidate_id)

      updated_candidate = Candidate |> Repo.get(candidate_id)

      expect(updated_candidate.pipeline_status_id) |> to(be(pass_id))
    end
  end

  context "get formatted name" do
    it "should concatinate first and last name" do
      candidate = insert(:candidate, first_name: "First", last_name: "Last")
      formatted_name = Candidate.get_full_name(candidate)

      expect(formatted_name |> to(be("First Last")))
    end
  end

  context "get formattted skills" do
    let :candidate, do: insert(:candidate, other_skills: "Other Skills")

    before do
      insert(:candidate_skill, skill: build(:skill, name: "Skill 1"), candidate: candidate())
      insert(:candidate_skill, skill: build(:skill, name: "Skill 2"), candidate: candidate())
    end

    it "should contain concatenated skills for the candidate in the result" do
      formatted_skills = Candidate
        |> preload([:skills])
        |> Repo.get(candidate().id)
        |> Candidate.get_formatted_skills

      expect(formatted_skills) |> to(have("Skill 1"))
      expect(formatted_skills) |> to(have("Skill 2"))
    end

    it "should append other skills for the candidate in the result" do
      insert(:candidate_skill, skill: Skill.other_skill, candidate: candidate())
      formatted_skills = Candidate
        |> preload([:skills])
        |> Repo.get(candidate().id)
        |> Candidate.get_formatted_skills

      expect(formatted_skills) |> to(have("Skill 1"))
      expect(formatted_skills) |> to(have("Skill 2"))
      expect(formatted_skills) |> to(have("Other Skills"))
    end
  end

  context "get formatted interviews" do
    let :candidate, do: insert(:candidate)
    let :interview_type_one, do: insert(:interview_type)
    let :interview_type_two, do: insert(:interview_type)

    before do
      insert(:interview, candidate: candidate(), interview_type: interview_type_one())
      insert(:interview, candidate: candidate(), interview_type: interview_type_two())
    end

    it "should return list of formatted interviews" do
      formatted_interviews = Candidate
        |> preload([:interviews, interviews: [:interview_type]])
        |> Repo.get(candidate().id)
        |> Candidate.get_formatted_interviews

      expect(Enum.count(formatted_interviews)) |> to(be(2))
    end
  end

  context "get formatted interviews with result" do
    let :candidate, do: insert(:candidate)
    let :interview_type_one, do: insert(:interview_type)
    let :interview_type_two, do: insert(:interview_type)

    before do
      insert(:interview, candidate: candidate(), interview_type: interview_type_one())
      insert(:interview, candidate: candidate(), interview_type: interview_type_two())
    end

    it "should call formatted interviews with result and panelists for all interviews" do
      allow Interview |> to(accept(:format_with_result_and_panelist, fn(_) -> ""  end))
      query = Interview |> preload([:interview_panelist, :interview_status, :interview_type])
      candidates = Candidate |> preload([:role, interviews: ^query]) |>  where([i], i.id == ^candidate().id) |> Repo.one
      [interview1, interview2] = candidates.interviews

      Candidate.get_formatted_interviews_with_result(candidates)

      expect Interview |> to(accepted :format_with_result_and_panelist, [interview1])
      expect Interview |> to(accepted :format_with_result_and_panelist, [interview2])
    end
  end

  context "get rounded experience" do
    it "should return experience in single precision" do
      candidate = insert(:candidate, experience: Decimal.new(4.67))

      actual_experience = Candidate.get_rounded_experience(candidate)

      expect(actual_experience) |> to(be("4.7"))
    end

    it "should not return experience mantissa-exponent format" do
      candidate = insert(:candidate, experience: Decimal.new(10.00))

      actual_experience = Candidate.get_rounded_experience(candidate)

      expect(actual_experience) |> to(be("10.0"))
    end
  end

  context "get candidate by id" do
    it "should return empty array when given an non-existing candidate id" do

      candidate = Candidate.get_candidate_by_id(1000) |> Repo.one
      expect(candidate) |> to(be_nil())
    end

    it "should return candidate details when given an existing candidate id" do
      candidate = insert(:candidate)
      insert(:interview, candidate: candidate)

      actual_candidate = Candidate.get_candidate_by_id(candidate.id) |> Repo.one

      expect(actual_candidate.id) |> to(be(candidate.id))
      expect(Enum.count(actual_candidate.interviews)) |> to(be(1))
    end
  end

  context "get the total no. of candidates in progress" do
    before do: Repo.delete_all(Candidate)

    it "should return the total no. of candidates in progress" do
      in_progress_pipeline = PipelineStatus.retrieve_by_name(PipelineStatus.in_progress)
      closed_pipeline = PipelineStatus.retrieve_by_name(PipelineStatus.closed)
      in_progress_candidate = insert(:candidate, other_skills: "Other Skills", pipeline_status: in_progress_pipeline)
      insert(:candidate, other_skills: "Other Skills", pipeline_status: closed_pipeline)        # closed candidate

      expect(Candidate.get_total_no_of_candidates_in_progress(in_progress_candidate.role_id)) |> to(be(1))
    end
  end

  context "get all candidates pursued after pipeline closure" do
    before do: Repo.delete_all(Candidate)

    let :role1, do: insert(:role, name: "Role1")
    let :interview_type1, do: insert(:interview_type, name: "interview_type1")
    let :pass_pipeline_status, do: PipelineStatus.retrieve_by_name(PipelineStatus.pass)
    let :closed_pipeline_status, do: PipelineStatus.retrieve_by_name(PipelineStatus.closed)

    it "should return candidate who is pursue in all interviews and pipeline is closed" do
      insert(:role_interview_type, role: role1(), interview_type: interview_type1())
      pursue = InterviewStatus.retrieve_by_name(InterviewStatus.pursue)
      candidate1 = insert(:candidate, pipeline_status: closed_pipeline_status(), role: role1(), pipeline_closure_time: get_start_of_current_week())
      insert(:interview, start_time: get_start_of_current_week(), interview_type: interview_type1(), interview_status: pursue, candidate: candidate1)

      {[candidates], _} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(current_week(), role1().id)

      expect(candidates.id) |> to(be(candidate1.id))
    end

    it "should NOT return candidate who is pursue in all interviews and pipeline is NOT closed" do
      progress_pipeline_status = PipelineStatus.retrieve_by_name(PipelineStatus.in_progress)
      insert(:role_interview_type, role: role1(), interview_type: interview_type1())
      pursue = InterviewStatus.retrieve_by_name(InterviewStatus.pursue)
      candidate1 = insert(:candidate, role: role1(), pipeline_status: progress_pipeline_status)
      insert(:interview, interview_type: interview_type1(), interview_status: pursue, candidate: candidate1)

      {candidates, _} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(current_week(), role1().id)

      expect(candidates) |> to(be([]))
    end

    it "should NOT return candidate who is pass in one interview after pipeline is closed" do
      insert(:role_interview_type, role: role1(), interview_type: interview_type1())
      pass = InterviewStatus.retrieve_by_name(InterviewStatus.pass)
      candidate1 = insert(:candidate, role: role1(), pipeline_status: closed_pipeline_status(), pipeline_closure_time: TimexHelper.utc_now() |> TimexHelper.add(-2, :days))
      insert(:interview, interview_type: interview_type1(), interview_status: pass, candidate: candidate1)

      {candidates, _} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(current_week(), role1().id)

      expect(candidates) |> to(be([]))
    end

    it "should NOT return candidate who is not completed all interviews after pipeline is closed" do
      insert(:role_interview_type, role: role1(), interview_type: interview_type1())
      insert(:candidate, role: role1(), pipeline_status: closed_pipeline_status(), pipeline_closure_time: TimexHelper.utc_now() |> TimexHelper.add(-2, :days))

      {candidates, _} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(current_week(), role1().id)

      expect(candidates) |> to(be([]))
    end
  end

  context "get all candidates rejected after pipeline closure" do
    before do: Repo.delete_all(Candidate)

    let :role1, do: insert(:role, name: "Role1")
    let :interview_type1, do: insert(:interview_type, name: "interview_type1")
    let :pass_pipeline_status, do: PipelineStatus.retrieve_by_name(PipelineStatus.pass)

    it "should NOT return candidate who is pursue in all interviews and pipeline is closed" do
      insert(:role_interview_type, role: role1(), interview_type: interview_type1())
      pursue = InterviewStatus.retrieve_by_name(InterviewStatus.pursue)
      candidate1 = insert(:candidate, pipeline_status: closed_pipeline_status(), role: role1(), pipeline_closure_time: TimexHelper.utc_now() |> TimexHelper.add(-1, :days))
      insert(:interview, start_time: get_start_of_current_week(), interview_type: interview_type1(), interview_status: pursue, candidate: candidate1)

      {_, candidates}= Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(current_week(), role1().id)

      expect(candidates) |> to(be([]))
    end

    it "should NOT return candidate whose pipeline is NOT closed" do
      progress_pipeline_status = PipelineStatus.retrieve_by_name(PipelineStatus.in_progress)
      insert(:role_interview_type, role: role1(), interview_type: interview_type1())
      pursue = InterviewStatus.retrieve_by_name(InterviewStatus.pursue)
      candidate1 = insert(:candidate, role: role1(), pipeline_status: progress_pipeline_status)
      insert(:interview, interview_type: interview_type1(), interview_status: pursue, candidate: candidate1)

      {_, candidates} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(current_week(), role1().id)

      expect(candidates) |> to(be([]))
    end

    it "should return candidate who is pass in one interview and pipeline is closed" do
      insert(:role_interview_type, role: role1(), interview_type: interview_type1())
      pass = InterviewStatus.retrieve_by_name(InterviewStatus.pass)
      candidate1 = insert(:candidate, role: role1(), pipeline_status: closed_pipeline_status(), pipeline_closure_time: get_start_of_current_week())
      insert(:interview, interview_type: interview_type1(), interview_status: pass, candidate: candidate1)

      {_, [candidates]} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(current_week(), role1().id)

      expect(candidates.id) |> to(be(candidate1.id))
    end

    it "should return candidate who is not completed all interviews after pipeline is closed" do
      insert(:role_interview_type, role: role1(), interview_type: interview_type1())
      candidate1 = insert(:candidate, role: role1(), pipeline_status: closed_pipeline_status(), pipeline_closure_time: get_start_of_current_week())

      {_, [candidates]} = Candidate.get_candidates_pursued_and_rejected_after_pipeline_closure_separately(current_week(), role1().id)

      expect(candidates.id) |> to(be(candidate1.id))
    end
  end

  context "get_no_of_pass_candidates_within_range" do
    before do: Repo.delete_all(Candidate)

    let :role1, do: insert(:role)
    let :interview_type1, do: insert(:interview_type, name: "interview_type1")

    it "should return 1 when a candidate is pass in an interview within range and pipeline is pass" do
      pass_pipeline_status = PipelineStatus.retrieve_by_name(PipelineStatus.pass)
      pass = InterviewStatus.retrieve_by_name(InterviewStatus.pass)
      candidate1 = insert(:candidate, pipeline_status: pass_pipeline_status, role: role1())
      insert(:interview, start_time: get_start_of_current_week(), interview_type: interview_type1(), interview_status: pass, candidate: candidate1)

      candidates_count = Candidate.get_no_of_pass_candidates_within_range(current_week(), role1().id)

      expect(candidates_count) |> to(be(1))
    end

    it "should return 0 when candidate is pass in an interview NOT IN RANGE and pipeline is pass" do
      pass_pipeline_status = PipelineStatus.retrieve_by_name(PipelineStatus.pass)
      pass = InterviewStatus.retrieve_by_name(InterviewStatus.pass)
      candidate1 = insert(:candidate, pipeline_status: pass_pipeline_status, role: role1())
      insert(:interview, start_time: TimexHelper.utc_now() |> TimexHelper.end_of_week |> TimexHelper.add(+1, :days), interview_type: interview_type1(), interview_status: pass, candidate: candidate1)

      candidates_count = Candidate.get_no_of_pass_candidates_within_range(current_week(), role1().id)

      expect(candidates_count) |> to(be(0))
    end

    it "should return 0 when candidate is pursue in an interview within range" do
      progress_pipeline_status = PipelineStatus.retrieve_by_name(PipelineStatus.in_progress)
      pursue = InterviewStatus.retrieve_by_name(InterviewStatus.pursue)
      candidate1 = insert(:candidate, pipeline_status: progress_pipeline_status, role: role1())
      insert(:interview, start_time: get_start_of_current_week(), interview_type: interview_type1(), interview_status: pursue, candidate: candidate1)

      candidates_count = Candidate.get_no_of_pass_candidates_within_range(current_week(), role1().id)

      expect(candidates_count) |> to(be(0))
    end
  end

  context "get_candidates_scheduled_for_date_and_interview_round" do
    before do: Repo.delete_all(Interview)

    let :interview_type, do: insert(:interview_type, priority: 2)

    it "should return empty array when there are no interviews" do
      result = Candidate.get_candidates_scheduled_for_date_and_interview_round(get_start_of_next_week(), interview_type().id, Enum.random([1, 2, 3])) |> Repo.all

      expect(result) |> to(be([]))
    end

    it "should return empty array when there are no interviews with lesser priority on the day" do
      insert(:interview, start_time: get_start_of_next_week(), interview_type: build(:interview_type, priority: 2))
      result = Candidate.get_candidates_scheduled_for_date_and_interview_round(get_start_of_next_week(), interview_type().id, Enum.random([1, 2, 3])) |> Repo.all

      expect(result) |> to(be([]))
    end

    it "should return empty array when there are no interviews on the day" do
      insert(:interview, start_time: get_start_of_next_week() |> TimexHelper.add(1, :days), interview_type: insert(:interview_type, priority: 1))
      insert(:interview, start_time: get_start_of_next_week() |> TimexHelper.add(-1, :days), interview_type: insert(:interview_type, priority: 1))
      result = Candidate.get_candidates_scheduled_for_date_and_interview_round(get_start_of_next_week(), interview_type().id, Enum.random([1, 2, 3])) |> Repo.all

      expect(result) |> to(be([]))
    end

    it "should return empty array when there is an interviews on the day with lesser priority for different role" do
      candidate = insert(:candidate)
      insert(:interview, start_time: get_start_of_next_week(), interview_type: build(:interview_type, priority: 1), candidate: candidate)

      result = Candidate.get_candidates_scheduled_for_date_and_interview_round(get_start_of_next_week() |> TimexHelper.add(5, :hours), interview_type().id, candidate.role_id + 1) |> Repo.all
      expect(result) |> to(be([]))
    end

    it "should return candidate when there is an interviews on the day with lesser priority for same role" do
      candidate = insert(:candidate)
      interview = insert(:interview, start_time: get_start_of_next_week(), interview_type: build(:interview_type, priority: 1), candidate: candidate)

      [result] = Candidate.get_candidates_scheduled_for_date_and_interview_round(get_start_of_next_week() |> TimexHelper.add(5, :hours), interview_type().id, candidate.role_id) |> Repo.all

      expect([result]) |> to_not(be([]))
      expect(result.id) |> to(be(interview.candidate_id))
    end
  end

  context "get_unique_skills_formatted" do
    before do: Repo.delete_all(Candidate)

    it "should concat all skills of given candidates" do
      candidate1 = insert(:candidate)
      candidate2 = insert(:candidate)
      candidate_excluded = insert(:candidate)
      insert(:candidate_skill, skill: build(:skill, name: "Skill 1"), candidate: candidate1)
      insert(:candidate_skill, skill: build(:skill, name: "Skill 2"), candidate: candidate1)
      insert(:candidate_skill, skill: build(:skill, name: "Skill 3"), candidate: candidate_excluded)

      result = Candidate.get_unique_skills_formatted([candidate1.id, candidate2.id])

      expect(result) |> to(be("Skill 1/Skill 2"))
      expect(result) |> to_not(have("Skill 3"))
    end
  end
end
