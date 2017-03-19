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
  alias RecruitxBackend.SignupCop
  alias RecruitxBackend.Slot
  alias RecruitxBackend.SlotPanelist
  alias RecruitxBackend.Team
  alias RecruitxBackend.TimexHelper
  alias RecruitxBackend.UpdateTeamDetails

  import Ecto.Query

  def role_factory do
    %Role{
      name: sanitize_name("#{Faker.Name.first_name} #{Faker.Name.last_name}")   # TODO: Find a way to specify from a list of known langugages
    }
  end

  def signup_cop_factory do
    %SignupCop{
      name: sanitize_name("#{Faker.Name.first_name} #{Faker.Name.last_name}")   # TODO: Find a way to specify from a list of known langugages
    }
  end

  def pipeline_status_factory do
    %PipelineStatus{
      name: sanitize_name("#{Faker.Name.first_name} #{Faker.Name.last_name}")   # TODO: Find a way to specify from a list of known langugages
    }
  end

  def skill_factory do
    %Skill{
      name: sanitize_name("#{Faker.Name.first_name} #{Faker.Name.last_name}")   # TODO: Find a way to specify from a list of known langugages
    }
  end

  def skill_ids_factory do
    insert_list(Enum.random(5..10), :skill)
    skill_ids = Repo.all(from s in Skill, select: s.id) |> Enum.shuffle
    %{skill_ids: skill_ids}
  end

  def interview_rounds_factory do
    insert_list(Enum.random(1..4), :interview_type)
    interview_type_ids = Repo.all(from it in InterviewType, select: it.id, limit: ^Enum.random(1..InterviewType.count)) |> Enum.shuffle
    interview_rounds = for n <- interview_type_ids do
      %{"interview_type_id" => n, "start_time" => getRandomDateTime()}
    end
    %{interview_rounds: interview_rounds}
  end

  def interview_type_factory do
    %InterviewType{
      name: sanitize_name("#{Faker.Name.first_name} #{Faker.Name.last_name}"),   # TODO: Find a way to specify from a list of known langugages
      priority: Enum.random(1..4),
      max_sign_up_limit: 2
    }
  end

  def panelist_details_factory do
    current_count = Repo.all(from p in PanelistDetails, select: p.role_id) |> Enum.count
    %PanelistDetails{
      panelist_login_name: sanitize_name("#{Faker.Name.first_name}"),
      role: build(:role),
      employee_id: (current_count + 1) |> Decimal.new
    }
  end

  def interview_factory do
    random_time = getRandomDateTime() |> TimexHelper.add(1, :days)
    %Interview{
      candidate: build(:candidate),
      interview_type: build(:interview_type),
      start_time: random_time,
      end_time: random_time |> TimexHelper.add(2, :hours),
      interview_status: nil
    }
  end

  def candidate_factory do
    %Candidate{
      first_name: sanitize_name(Faker.Name.first_name),   # TODO: Find a way to specify from a list of known langugages
      last_name: sanitize_name(Faker.Name.last_name),   # TODO: Find a way to specify from a list of known langugages
      experience: Decimal.new(1.23),
      role: build(:role),
      pipeline_status: PipelineStatus.retrieve_by_name(PipelineStatus.in_progress)
    }
  end

  def slot_factory do
    random_time = getRandomDateTime() |> TimexHelper.add(1, :days)
    %Slot{
      role: build(:role),
      start_time: random_time,
      end_time: random_time |> TimexHelper.add(1, :hours),
      interview_type: build(:interview_type)
    }
  end

  def candidate_skill_factory do
    %CandidateSkill{
      candidate: build(:candidate),
      skill: build(:skill)
    }
  end

  def interview_panelist_factory do
    %InterviewPanelist{
      panelist_login_name: sanitize_name(Faker.Name.first_name),   # TODO: Find a way to specify from a list of known langugages
      interview: build(:interview)
    }
  end

  def slot_panelist_factory do
    %SlotPanelist{
      panelist_login_name: sanitize_name(Faker.Name.first_name),   # TODO: Find a way to specify from a list of known langugages
      slot: build(:slot)
    }
  end

  def interview_status_factory do
    %InterviewStatus{
      name: sanitize_name("#{Faker.Name.first_name} #{Faker.Name.last_name}")   # TODO: Find a way to specify from a list of known langugages
    }
  end

  def update_team_details_factory do
    %UpdateTeamDetails{
      panelist_login_name: sanitize_name("#{Faker.Name.first_name}"),
      interview_panelist: build(:interview_panelist),
      processed: false
    }
  end

  def team_factory do
    %Team{
      name: sanitize_name("#{Faker.Name.first_name} #{Faker.Name.last_name}")
    }
  end

  def feedback_image_factory do
    %FeedbackImage{
      file_name: sanitize_name(Faker.Name.first_name),
      interview: build(:interview)
    }
  end

  def experience_matrix_factory do
    %ExperienceMatrix{
      panelist_experience_lower_bound: Decimal.new(Enum.random(1..99)),
      candidate_experience_lower_bound: Decimal.new(Enum.random(1..99)),
      candidate_experience_upper_bound: Decimal.new(Enum.random(1..99)),
      interview_type: build(:interview_type),
      role: build(:role)
    }
  end

  def role_skill_factory do
    %RoleSkill{
      role: build(:role),
      skill: build(:skill)
    }
  end

  def role_interview_type_factory do
    %RoleInterviewType{
      role: build(:role),
      interview_type: build(:interview_type)
    }
  end

  # def weekend_drive_factory do
  #   start_date = getRandomDateTime() |> TimexHelper.add(1, :days) |> Timex.to_date()
  #   %WeekendDrive{
  #     role: build(:role),
  #     start_date: start_date,
  #     end_date: start_date |> TimexHelper.add(1, :days),
  #     no_of_candidates: Enum.random(10..20)
  #   }
  # end

  defp getRandomDateTime do
    TimexHelper.utc_now() |> TimexHelper.add(1, :hours)
  end

  defp sanitize_name(name) do
    name |> String.replace("'", "")
  end
end
