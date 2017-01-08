defmodule RecruitxBackend.Factory do
  use ExMachina.Ecto, repo: RecruitxBackend.Repo

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.ExperienceMatrix
  alias RecruitxBackend.FeedbackImage
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.InterviewStatus
  alias RecruitxBackend.InterviewType
  alias RecruitxBackend.PanelistDetails
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.Repo
  alias RecruitxBackend.Role
  alias RecruitxBackend.RoleInterviewType
  alias RecruitxBackend.RoleSkill
  alias RecruitxBackend.Skill
  alias RecruitxBackend.Slot
  alias RecruitxBackend.SlotPanelist
  alias RecruitxBackend.Team
  alias RecruitxBackend.TimexHelper
  alias RecruitxBackend.UpdateTeamDetails

  import Ecto.Query

  def factory(:role) do
    %Role{
      name: sanitize_name("#{Faker.Name.first_name} #{Faker.Name.last_name}")   # TODO: Find a way to specify from a list of known langugages
    }
  end

  def factory(:pipeline_status) do
    %PipelineStatus{
      name: sanitize_name("#{Faker.Name.first_name} #{Faker.Name.last_name}")   # TODO: Find a way to specify from a list of known langugages
    }
  end

  def factory(:skill) do
    %Skill{
      name: sanitize_name("#{Faker.Name.first_name} #{Faker.Name.last_name}")   # TODO: Find a way to specify from a list of known langugages
    }
  end

  def factory(:skill_ids) do
    create(:skill)
    skill_ids = Repo.all(from s in Skill, select: s.id) |> Enum.shuffle
    %{skill_ids: skill_ids}
  end

  def factory(:interview_rounds) do
    current_interview_count = Ectoo.count(Repo, InterviewType)
    create(:interview_type, id: current_interview_count + 1)
    create(:interview_type, id: current_interview_count + 2)
    interview_rounds = for n <- 1..:rand.uniform(2) do
      %{"interview_type_id" => current_interview_count + n, "start_time" => getRandomDateTime}
    end
    %{interview_rounds: interview_rounds}
  end

  def factory(:interview_type) do
    %InterviewType{
      name: sanitize_name("#{Faker.Name.first_name} #{Faker.Name.last_name}"),   # TODO: Find a way to specify from a list of known langugages
      priority: :rand.uniform(4),
      max_sign_up_limit: 2
    }
  end

  def factory(:panelist_details) do
    current_count = Repo.all(from p in PanelistDetails, select: p.role_id) |> Enum.count
    %PanelistDetails{
      panelist_login_name: sanitize_name("#{Faker.Name.first_name}"),
      role_id: create(:role).id,
      employee_id: (current_count + 1) |> Decimal.new
    }
  end

  def factory(:interview) do
    random_time = getRandomDateTime
    %Interview{
      candidate_id: create(:candidate).id,
      interview_type_id: create(:interview_type).id,
      start_time: random_time,
      end_time: random_time |> TimexHelper.add(2, :hours),
      interview_status_id: nil
    }
  end

  def factory(:candidate) do
    %Candidate{
      first_name: sanitize_name(Faker.Name.first_name),   # TODO: Find a way to specify from a list of known langugages
      last_name: sanitize_name(Faker.Name.last_name),   # TODO: Find a way to specify from a list of known langugages
      experience: Decimal.new(1.23),
      role_id: create(:role).id,
      pipeline_status_id: PipelineStatus.retrieve_by_name(PipelineStatus.in_progress).id
    }
  end

  def factory(:slot) do
    random_time = getRandomDateTime
    %Slot{
      role_id: create(:role).id,
      start_time: random_time,
      end_time: random_time |> TimexHelper.add(1, :hours),
      interview_type_id: create(:interview_type).id,
    }
  end

  def factory(:candidate_skill) do
    %CandidateSkill{
      candidate_id: create(:candidate).id,
      skill_id: create(:skill).id
    }
  end

  def factory(:interview_panelist) do
    %InterviewPanelist{
      panelist_login_name: sanitize_name(Faker.Name.first_name),   # TODO: Find a way to specify from a list of known langugages
      interview_id: create(:interview).id
    }
  end

  def factory(:slot_panelist) do
    %SlotPanelist{
      panelist_login_name: sanitize_name(Faker.Name.first_name),   # TODO: Find a way to specify from a list of known langugages
      slot_id: create(:slot).id
    }
  end

  def factory(:interview_status) do
    %InterviewStatus{
      name: sanitize_name("#{Faker.Name.first_name} #{Faker.Name.last_name}")   # TODO: Find a way to specify from a list of known langugages
    }
  end

  def factory(:update_team_details) do
    %UpdateTeamDetails{
      panelist_login_name: sanitize_name("#{Faker.Name.first_name}"),
      interview_panelist_id: create(:interview_panelist).id,
      processed: false
    }
  end

  def factory(:team) do
    %Team{
      name: sanitize_name("#{Faker.Name.first_name} #{Faker.Name.last_name}")
    }
  end

  def factory(:feedback_image) do
    %FeedbackImage{
      file_name: sanitize_name(Faker.Name.first_name),
      interview_id: create(:interview).id
    }
  end

  def factory(:experience_matrix) do
    %ExperienceMatrix{
      panelist_experience_lower_bound: Decimal.new(:rand.uniform(99)),
      candidate_experience_lower_bound: Decimal.new(:rand.uniform(99)),
      candidate_experience_upper_bound: Decimal.new(:rand.uniform(99)),
      interview_type_id: create(:interview_type).id,
      role_id: create(:role).id
    }
  end

  def factory(:role_skill) do
    %RoleSkill{
      role_id: create(:role).id,
      skill_id: create(:skill).id
    }
  end

  def factory(:role_interview_type) do
    %RoleInterviewType{
      role_id: create(:role).id,
      interview_type_id: create(:interview_type).id
    }
  end

  defp getRandomDateTime do
    TimexHelper.utc_now()
  end

  defp sanitize_name(name) do
    name |> String.replace("'", "")
  end
end
