defmodule RecruitxBackend.WeeklyStatusUpdateSpec do
  use ESpec.Phoenix, model: RecruitxBackend.WeeklySignupReminder

  import Ecto.Query
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.PipelineStatus
  alias RecruitxBackend.WeeklyStatusUpdate
  alias RecruitxBackend.MailHelper
  alias Timex.Date
  alias Timex.DateFormat
  alias RecruitxBackend.PreviousWeek

  describe "filter out candidates without interviews" do

    it "should return candidates with interviews" do
      candidate1 = %{interviews: ["a"]}
      candidate2 = %{interviews: []}
      candidates = [ candidate1, candidate2 ]

      [result] = WeeklyStatusUpdate.filter_out_candidates_without_interviews(candidates)

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

      [result] = WeeklyStatusUpdate.construct_view_data(candidates)

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

      %{starting: start_date, ending: end_date} = PreviousWeek.get
      {:ok, from_date} = start_date |> DateFormat.format("{D}/{M}/{YY}")
      {:ok, to_date} = end_date |> DateFormat.format("{D}/{M}/{YY}")

      allow PipelineStatus |> to(accept(:in_progress, fn()-> candidate_pipeline_status.name end))

      query = Interview |> preload([:interview_panelist, :interview_status, :interview_type])
      candidates_weekly_status = Candidate |> preload([:role, interviews: ^query]) |> Repo.all
      candidates = candidates_weekly_status
      |> WeeklyStatusUpdate.filter_out_candidates_without_interviews
      |> WeeklyStatusUpdate.construct_view_data
      summary = %{candidates_appeared: 1,
        candidates_in_progress: 1,
        candidates_pursued: 0,
        candidates_rejected: 0,
        interviews_count: 1
      }
      allow Swoosh.Templates |> to(accept(:weekly_status_update, fn(_, _, _, _) -> "html content" end))

      WeeklyStatusUpdate.execute

      expect Swoosh.Templates |> to(accepted :weekly_status_update,[from_date, to_date, candidates, summary])
    end

    it "should call MailmanExtensions deliver with correct arguments" do
      create(:interview, interview_type_id: 1, start_time: get_start_of_current_week)
      email = %{
          subject: "[RecruitX] Weekly Status Update",
          to: System.get_env("WEEKLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES") |> String.split,
          html_body: "html content"
      }
      allow Swoosh.Templates |> to(accept(:weekly_status_update, fn(_, _, _, _) -> "html content"  end))
      allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      WeeklyStatusUpdate.execute

      expect Swoosh.Templates |> to(accepted :weekly_status_update)
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

      allow Swoosh.Templates |> to(accept(:weekly_status_update_default, fn(_, _) -> "html content"  end))
      allow Swoosh.Templates |> to(accept(:weekly_status_update, fn(_, _, _, _) -> "html content"  end))
      allow MailHelper |> to(accept(:deliver, fn(_) -> "" end))

      WeeklyStatusUpdate.execute

      expect Swoosh.Templates |> to(accepted :weekly_status_update_default)
      expect Swoosh.Templates |> to_not(accepted :weekly_status_update)
      expect MailHelper |> to(accepted :deliver, [email])
    end

    it "should be called every week on saturday at 6.0am UTC" do
      job = Quantum.find_job(:weekly_status_update)

      expect(job.schedule) |> to(be("30 0 * * 6"))
      expect(job.task) |> to(be({"RecruitxBackend.WeeklyStatusUpdate", "execute"}))
    end
  end
end
