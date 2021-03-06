defmodule RecruitxBackend.StatusUpdateSpec do
  use ESpec.Phoenix, model: RecruitxBackend.StatusUpdate

  import Ecto.Query

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Interview
  alias RecruitxBackend.MailHelper
  alias RecruitxBackend.PanelistDetails
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.Role
  alias RecruitxBackend.Slot
  alias RecruitxBackend.StatusUpdate
  alias RecruitxBackend.Scheduler
  alias RecruitxBackend.Timer
  alias RecruitxBackend.TimexHelper

  describe "status update spec" do
    before do: Repo.delete_all Interview
    before do: Repo.delete_all Slot
    before do: Repo.delete_all Candidate
    before do: Repo.delete_all PanelistDetails
    before do: Repo.delete_all Role
    before do: System.put_env("WEEKLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES", "addresses")
    before do: System.put_env("MONTHLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES", "addresses")
    before do: System.put_env("QUARTERLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES", "addresses")

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

        interview = insert(:interview, start_time: get_start_of_current_week() )
        candidate_pipeline_status_id = Repo.get(Candidate, interview.candidate_id).pipeline_status_id
        candidate_pipeline_status = Repo.get(PipelineStatus, candidate_pipeline_status_id)

        %{starting: start_date, ending: end_date} = Timer.get_current_week_weekdays
        from_date = start_date |> TimexHelper.format("%D")
        to_date = end_date |> TimexHelper.format("%D")

        allow PipelineStatus |> to(accept(:in_progress, fn()-> candidate_pipeline_status.name end))

        query = Interview |> preload([:interview_panelist, :interview_status, :interview_type])
        candidates_weekly_status = Candidate |> preload([:role, interviews: ^query]) |> Repo.all
        candidates = candidates_weekly_status
        |> StatusUpdate.filter_out_candidates_without_interviews
        |> StatusUpdate.construct_view_data

        candidate_role = (from r in Role, join: c in assoc(r, :candidates), where: c.id == ^interview.candidate_id) |> Repo.one

        summary = %{candidate_role.name => %{
          candidates_appeared: 1,
          candidates_in_progress: 1,
          candidates_pursued: 0,
          candidates_rejected: 0,
          interviews_count: 1,
          candidates: candidates
        }}
        allow Swoosh.Templates |> to(accept(:status_update, fn(_, _, _, _) -> "html content" end))

        StatusUpdate.execute_weekly

        expect Swoosh.Templates |> to(accepted :status_update,[from_date, to_date, summary, false])
      end

      it "should call MailmanExtensions deliver with correct arguments" do
        insert(:interview, start_time: get_start_of_current_week())
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
        insert(:interview, start_time: get_start_of_current_week() |> TimexHelper.add(-1, :days))
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
        job = Scheduler.find_job(:weekly_status_update)

        # expect(job.schedule) |> to(be("30 0 * * 6"))
        expect(job.task) |> to(be({RecruitxBackend.StatusUpdate, :execute_weekly, []}))
      end
    end

    describe "execute monthly status update" do
      it "should filter previous months interviews and construct email" do
        interview = insert(:interview, start_time: get_date_of_previous_month())
        candidate_pipeline_status_id = Repo.get(Candidate, interview.candidate_id).pipeline_status_id
        candidate_pipeline_status = Repo.get(PipelineStatus, candidate_pipeline_status_id)

        %{starting: start_date, ending: end_date} = Timer.get_previous_month
        from_date = start_date |> TimexHelper.format("%D")
        to_date = end_date |> TimexHelper.format("%D")

        allow PipelineStatus |> to(accept(:in_progress, fn()-> candidate_pipeline_status.name end))

        query = Interview |> preload([:interview_panelist, :interview_status, :interview_type])
        candidates_weekly_status = Candidate |> preload([:role, interviews: ^query]) |> Repo.all
        candidates = candidates_weekly_status
        |> StatusUpdate.filter_out_candidates_without_interviews
        |> StatusUpdate.construct_view_data

        candidate_role = (from r in Role, join: c in assoc(r, :candidates), where: c.id == ^interview.candidate_id) |> Repo.one

        summary = %{candidate_role.name => %{candidates_appeared: 1,
          candidates_in_progress: 1,
          candidates_pursued: 0,
          candidates_rejected: 0,
          interviews_count: 1,
          candidates: candidates
        }}
        allow Swoosh.Templates |> to(accept(:status_update, fn(_, _, _, _) -> "html content" end))

        StatusUpdate.execute_monthly

        expect Swoosh.Templates |> to(accepted :status_update,[from_date, to_date, summary, true])
      end

      it "should call MailmanExtensions deliver with correct arguments" do
        insert(:interview, start_time: get_date_of_previous_month())
        subject_suffix = TimexHelper.format(Timer.get_previous_month.starting, " - %b %Y")
        email = %{
            subject: "[RecruitX] Monthly Status Update" <> subject_suffix,
            to: System.get_env("MONTHLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
            html_body: "html content"
        }
        allow Swoosh.Templates |> to(accept(:status_update, fn(_, _, _, _) -> "html content"  end))
        allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

        StatusUpdate.execute_monthly

        expect Swoosh.Templates |> to(accepted :status_update)
        expect MailHelper |> to(accepted :deliver, [email])
      end

      it "should be called every month on saturday at 6.0am UTC" do
        job = Scheduler.find_job(:monthly_status_update)

        # expect(job.schedule) |> to(be("30 0 1 * *"))
        expect(job.task) |> to(be({RecruitxBackend.StatusUpdate, :execute_monthly, []}))
      end

      it "should send a default mail if there are no interview in previous month" do
        subject_suffix = TimexHelper.format(Timer.get_previous_month.starting, " - %b %Y")

        insert(:interview, start_time: TimexHelper.utc_now())
        email = %{
            subject: "[RecruitX] Monthly Status Update" <> subject_suffix,
            to: System.get_env("MONTHLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
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
        interview = insert(:interview, start_time: get_date_of_previous_quarter())
        candidate_pipeline_status_id = Repo.get(Candidate, interview.candidate_id).pipeline_status_id
        candidate_pipeline_status = Repo.get(PipelineStatus, candidate_pipeline_status_id)

        %{starting: start_date, ending: end_date} = Timer.get_previous_quarter
        from_date = start_date |> TimexHelper.format("%D")
        to_date = end_date |> TimexHelper.format("%D")

        allow PipelineStatus |> to(accept(:in_progress, fn()-> candidate_pipeline_status.name end))

        query = Interview |> preload([:interview_panelist, :interview_status, :interview_type])
        candidates_weekly_status = Candidate |> preload([:role, interviews: ^query]) |> Repo.all
        candidates = candidates_weekly_status
        |> StatusUpdate.filter_out_candidates_without_interviews
        |> StatusUpdate.construct_view_data

        candidate_role = (from r in Role, join: c in assoc(r, :candidates), where: c.id == ^interview.candidate_id) |> Repo.one

        summary = %{candidate_role.name => %{candidates_appeared: 1,
          candidates_in_progress: 1,
          candidates_pursued: 0,
          candidates_rejected: 0,
          interviews_count: 1,
          candidates: candidates
        }}
        allow Swoosh.Templates |> to(accept(:status_update, fn(_, _, _, _) -> "html content" end))

        StatusUpdate.execute_quarterly

        expect Swoosh.Templates |> to(accepted :status_update,[from_date, to_date, summary, true])
      end

      it "should call MailmanExtensions deliver with correct arguments" do
        insert(:interview, start_time: get_date_of_previous_quarter())
        time = Timer.get_previous_quarter
        subject_suffix = " - Q" <> to_string(div(time.starting.month + 2, 4) + 1) <> " " <> to_string(time.starting.year)
        email = %{
            subject: "[RecruitX] Quarterly Status Update" <> subject_suffix,
            to: System.get_env("QUARTERLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
            html_body: "html content"
        }
        allow Swoosh.Templates |> to(accept(:status_update, fn(_, _, _, _) -> "html content"  end))
        allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

        StatusUpdate.execute_quarterly

        expect Swoosh.Templates |> to(accepted :status_update)
        expect MailHelper |> to(accepted :deliver, [email])
      end

      it "should be called on jan 1 st at 6.0am UTC" do
        job = Scheduler.find_job(:jan_status_update)
        # expect(job.schedule) |> to(be(~e(<<"foo">>)))
        expect(job.task) |> to(be({RecruitxBackend.StatusUpdate, :execute_quarterly, []}))
      end

      it "should be called on april 1 st at 6.0am UTC" do
        job = Scheduler.find_job(:april_status_update)

        # expect(job.schedule) |> to(be("~e[30 0 1 4 * *]"))
        expect(job.task) |> to(be({RecruitxBackend.StatusUpdate, :execute_quarterly, []}))
      end

      it "should be called on july 1 st at 6.0am UTC" do
        job = Scheduler.find_job(:july_status_update)

        # expect(job.schedule) |> to(be("~e[30 0 1 7 * *]"))
        expect(job.task) |> to(be({RecruitxBackend.StatusUpdate, :execute_quarterly, []}))
      end

      it "should be called on oct 1 st at 6.0am UTC" do
        job = Scheduler.find_job(:oct_status_update)

        # expect(job.schedule) |> to(be("30 0 1 10 *"))
        expect(job.task) |> to(be({RecruitxBackend.StatusUpdate, :execute_quarterly, []}))
      end

      it "should send a default mail if there are no interview in previous month" do
        insert(:interview, start_time: TimexHelper.utc_now())
        time = Timer.get_previous_quarter
        subject_suffix = " - Q" <> to_string(div(time.starting.month + 2, 4) + 1) <> " " <> to_string(time.starting.year)

        email = %{
            subject: "[RecruitX] Quarterly Status Update" <> subject_suffix,
            to: System.get_env("QUARTERLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
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
end
