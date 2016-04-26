defmodule RecruitxBackend.StatusUpdateSpec do
  use ESpec.Phoenix, model: RecruitxBackend.StatusUpdate

  import Ecto.Query
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.StatusUpdate
  alias RecruitxBackend.MailHelper
  alias Timex.Date
  alias Timex.DateFormat
  alias RecruitxBackend.TimeRange

  describe "filter out candidates without interviews" do

    it "should return candidates with interviews" do
      candidate1 = %{interviews: ["a"]}
      candidate2 = %{interviews: []}
      candidates = [ candidate1, candidate2 ]

      [result] = StatusUpdate.filter_out_candidates_without_interviews(candidates)

      expect(result) |> to(be(candidate1))
    end
  end

  describe "construct view data" do

    it "should return name, role and interviews of candidates" do
      candidate = %{a: "a", last_name: "last_name", first_name: "first_name", role: %{ name: "role" }, interviews: ["a"]}
      candidates = [candidate]
      allow Candidate |> to(accept(:get_formatted_interviews_with_result, fn(_) -> "interviews"  end))
      expected_result = %{
        name: "first_name" <> " " <> "last_name",
        role: "role",
        interviews: "interviews",
      }

      [result] = StatusUpdate.construct_view_data(candidates)

      expect(result) |> to(be(expected_result))
      expect Candidate |> to(accepted :get_formatted_interviews_with_result)
    end
  end


  describe "execute weekly status update" do

    it "should filter previous weeks interviews and construct email" do
      Repo.delete_all Candidate
      Repo.delete_all Interview

      interview = create(:interview, interview_type_id: 1, start_time: get_start_of_current_week )
      candidate_pipeline_status_id = Repo.get(Candidate, interview.candidate_id).pipeline_status_id
      candidate_pipeline_status = Repo.get(PipelineStatus, candidate_pipeline_status_id)

      %{starting: start_date, ending: end_date} = TimeRange.get_previous_week
      {:ok, from_date} = start_date |> DateFormat.format("{D}/{M}/{YY}")
      {:ok, to_date} = end_date |> DateFormat.format("{D}/{M}/{YY}")

      allow PipelineStatus |> to(accept(:in_progress, fn()-> candidate_pipeline_status.name end))

      query = Interview |> preload([:interview_panelist, :interview_status, :interview_type])
      candidates_weekly_status = Candidate |> preload([:role, interviews: ^query]) |> Repo.all
      candidates = candidates_weekly_status
      |> StatusUpdate.filter_out_candidates_without_interviews
      |> StatusUpdate.construct_view_data
      summary = %{candidates_appeared: 1,
        candidates_in_progress: 1,
        candidates_pursued: 0,
        candidates_rejected: 0,
        interviews_count: 1
      }
      allow Swoosh.Templates |> to(accept(:status_update, fn(_, _, _, _) -> "html content" end))

      StatusUpdate.execute_weekly

      expect Swoosh.Templates |> to(accepted :status_update,[from_date, to_date, candidates, summary])
    end

    it "should call MailmanExtensions deliver with correct arguments" do
      create(:interview, interview_type_id: 1, start_time: get_start_of_current_week)
      email = %{
          subject: "[RecruitX] Weekly Status Update",
          to: System.get_env("WEEKLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
          html_body: "html content"
      }
      allow Swoosh.Templates |> to(accept(:status_update, fn(_, _, _, _) -> "html content"  end))
      allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      StatusUpdate.execute_weekly

      expect Swoosh.Templates |> to(accepted :status_update)
      expect MailHelper |> to(accepted :deliver, [email])
    end

    it "should send a default mail if there are no interview in previous week" do
      Repo.delete_all Candidate
      Repo.delete_all Interview
      create(:interview, interview_type_id: 1, start_time: get_start_of_current_week |> Date.shift(days: -1))
      email = %{
          subject: "[RecruitX] Weekly Status Update",
          to: System.get_env("WEEKLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
          html_body: "html content"
      }

      allow Swoosh.Templates |> to(accept(:status_update_default, fn(_, _) -> "html content"  end))
      allow Swoosh.Templates |> to(accept(:status_update, fn(_, _, _, _) -> "html content"  end))
      allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      StatusUpdate.execute_weekly

      expect Swoosh.Templates |> to(accepted :status_update_default)
      expect Swoosh.Templates |> to_not(accepted :status_update)
      expect MailHelper |> to(accepted :deliver, [email])
    end

    it "should be called every week on saturday at 6.0am UTC" do
      job = Quantum.find_job(:weekly_status_update)

      expect(job.schedule) |> to(be("30 0 * * 6"))
      expect(job.task) |> to(be({"RecruitxBackend.StatusUpdate", "execute_weekly"}))
    end
  end

  describe "execute monthly status update" do

    it "should filter previous months interviews and construct email" do
      Repo.delete_all Candidate
      Repo.delete_all Interview

      interview = create(:interview, interview_type_id: 1, start_time: get_start_of_previous_month)
      candidate_pipeline_status_id = Repo.get(Candidate, interview.candidate_id).pipeline_status_id
      candidate_pipeline_status = Repo.get(PipelineStatus, candidate_pipeline_status_id)

      %{starting: start_date, ending: end_date} = TimeRange.get_previous_month
      {:ok, from_date} = start_date |> DateFormat.format("{D}/{M}/{YY}")
      {:ok, to_date} = end_date |> DateFormat.format("{D}/{M}/{YY}")

      allow PipelineStatus |> to(accept(:in_progress, fn()-> candidate_pipeline_status.name end))

      query = Interview |> preload([:interview_panelist, :interview_status, :interview_type])
      candidates_weekly_status = Candidate |> preload([:role, interviews: ^query]) |> Repo.all
      candidates = candidates_weekly_status
      |> StatusUpdate.filter_out_candidates_without_interviews
      |> StatusUpdate.construct_view_data
      summary = %{candidates_appeared: 1,
        candidates_in_progress: 1,
        candidates_pursued: 0,
        candidates_rejected: 0,
        interviews_count: 1
      }
      allow Swoosh.Templates |> to(accept(:status_update, fn(_, _, _, _) -> "html content" end))

      StatusUpdate.execute_monthly

      expect Swoosh.Templates |> to(accepted :status_update,[from_date, to_date, candidates, summary])
    end

    it "should call MailmanExtensions deliver with correct arguments" do
      create(:interview, interview_type_id: 1, start_time: get_start_of_previous_month)
      email = %{
          subject: "[RecruitX] Monthly Status Update",
          to: System.get_env("WEEKLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
          html_body: "html content"
      }
      allow Swoosh.Templates |> to(accept(:status_update, fn(_, _, _, _) -> "html content"  end))
      allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      StatusUpdate.execute_monthly

      expect Swoosh.Templates |> to(accepted :status_update)
      expect MailHelper |> to(accepted :deliver, [email])
    end

    it "should be called every month on saturday at 6.0am UTC" do
      job = Quantum.find_job(:monthly_status_update)

      expect(job.schedule) |> to(be("30 0 1 * *"))
      expect(job.task) |> to(be({"RecruitxBackend.StatusUpdate", "execute_monthly"}))
    end

    it "should send a default mail if there are no interview in previous month" do
      Repo.delete_all Candidate
      Repo.delete_all Interview
      create(:interview, interview_type_id: 1, start_time: Date.now )
      email = %{
          subject: "[RecruitX] Monthly Status Update",
          to: System.get_env("WEEKLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
          html_body: "html content"
      }

      allow Swoosh.Templates |> to(accept(:status_update_default, fn(_, _) -> "html content"  end))
      allow Swoosh.Templates |> to(accept(:status_update, fn(_, _, _, _) -> "html content"  end))
      allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      StatusUpdate.execute_monthly

      expect Swoosh.Templates |> to(accepted :status_update_default)
      expect Swoosh.Templates |> to_not(accepted :status_update)
      expect MailHelper |> to(accepted :deliver, [email])
    end
  end

  describe "execute quarterly status update" do

    it "should filter previous quarters interviews and construct email" do
      Repo.delete_all Candidate
      Repo.delete_all Interview

      interview = create(:interview, interview_type_id: 1, start_time: get_start_of_previous_quarter)
      candidate_pipeline_status_id = Repo.get(Candidate, interview.candidate_id).pipeline_status_id
      candidate_pipeline_status = Repo.get(PipelineStatus, candidate_pipeline_status_id)

      %{starting: start_date, ending: end_date} = TimeRange.get_previous_quarter
      {:ok, from_date} = start_date |> DateFormat.format("{D}/{M}/{YY}")
      {:ok, to_date} = end_date |> DateFormat.format("{D}/{M}/{YY}")

      allow PipelineStatus |> to(accept(:in_progress, fn()-> candidate_pipeline_status.name end))

      query = Interview |> preload([:interview_panelist, :interview_status, :interview_type])
      candidates_weekly_status = Candidate |> preload([:role, interviews: ^query]) |> Repo.all
      candidates = candidates_weekly_status
      |> StatusUpdate.filter_out_candidates_without_interviews
      |> StatusUpdate.construct_view_data
      summary = %{candidates_appeared: 1,
        candidates_in_progress: 1,
        candidates_pursued: 0,
        candidates_rejected: 0,
        interviews_count: 1
      }
      allow Swoosh.Templates |> to(accept(:status_update, fn(_, _, _, _) -> "html content" end))

      StatusUpdate.execute_quarterly

      expect Swoosh.Templates |> to(accepted :status_update,[from_date, to_date, candidates, summary])
    end

    it "should call MailmanExtensions deliver with correct arguments" do
      create(:interview, interview_type_id: 1, start_time: get_start_of_previous_quarter)
      email = %{
          subject: "[RecruitX] Quarterly Status Update",
          to: System.get_env("WEEKLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
          html_body: "html content"
      }
      allow Swoosh.Templates |> to(accept(:status_update, fn(_, _, _, _) -> "html content"  end))
      allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      StatusUpdate.execute_quarterly

      expect Swoosh.Templates |> to(accepted :status_update)
      expect MailHelper |> to(accepted :deliver, [email])
    end

    it "should be called on jan 1 st at 6.0am UTC" do
      job = Quantum.find_job(:jan_status_update)

      expect(job.schedule) |> to(be("30 0 1 1 *"))
      expect(job.task) |> to(be({"RecruitxBackend.StatusUpdate", "execute_quarterly"}))
    end

    it "should be called on april 1 st at 6.0am UTC" do
      job = Quantum.find_job(:april_status_update)

      expect(job.schedule) |> to(be("30 0 1 4 *"))
      expect(job.task) |> to(be({"RecruitxBackend.StatusUpdate", "execute_quarterly"}))
    end

    it "should be called on july 1 st at 6.0am UTC" do
      job = Quantum.find_job(:july_status_update)

      expect(job.schedule) |> to(be("30 0 1 7 *"))
      expect(job.task) |> to(be({"RecruitxBackend.StatusUpdate", "execute_quarterly"}))
    end

    it "should be called on oct 1 st at 6.0am UTC" do
      job = Quantum.find_job(:oct_status_update)

      expect(job.schedule) |> to(be("30 0 1 10 *"))
      expect(job.task) |> to(be({"RecruitxBackend.StatusUpdate", "execute_quarterly"}))
    end

    it "should send a default mail if there are no interview in previous month" do
      Repo.delete_all Candidate
      Repo.delete_all Interview
      create(:interview, interview_type_id: 1, start_time: Date.now )
      email = %{
          subject: "[RecruitX] Quarterly Status Update",
          to: System.get_env("WEEKLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
          html_body: "html content"
      }

      allow Swoosh.Templates |> to(accept(:status_update_default, fn(_, _) -> "html content"  end))
      allow Swoosh.Templates |> to(accept(:status_update, fn(_, _, _, _) -> "html content"  end))
      allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      StatusUpdate.execute_quarterly

      expect Swoosh.Templates |> to(accepted :status_update_default)
      expect Swoosh.Templates |> to_not(accepted :status_update)
      expect MailHelper |> to(accepted :deliver, [email])
    end
  end
end
