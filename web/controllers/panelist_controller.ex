defmodule RecruitxBackend.PanelistController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.SlotPanelist
  alias RecruitxBackend.ChangesetView
  alias RecruitxBackend.Candidate
  alias Swoosh.Templates
  alias RecruitxBackend.MailHelper
  alias Timex.DateFormat
  alias Timex.Date
  alias Timex.Timezone

  def create(conn, %{"interview_panelist" => post_params}) do
    interview_panelist_changeset = InterviewPanelist.changeset(%InterviewPanelist{}, post_params)
    case Repo.insert(interview_panelist_changeset) do
      {:ok, interview_panelist} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", panelist_path(conn, :show, interview_panelist))
        |> render("panelist.json", interview_panelist: interview_panelist)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  def create(conn, %{"slot_panelist" => slot_panelist_params}) do
    slot_panelist_changeset = SlotPanelist.changeset(%SlotPanelist{}, slot_panelist_params)

    case Repo.insert(slot_panelist_changeset) do
      {:ok, slot_panelist} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", panelist_path(conn, :show, slot_panelist))
        |> render("panelist.json", slot_panelist: slot_panelist)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(%{path_info: ["panelists", _]} = conn, %{"id" => id}) do
    Repo.delete_all(from i in InterviewPanelist, where: i.id == ^id)
    send_resp(conn, :no_content, "")
  end

  def delete(%{path_info: ["remove_panelists", _]} = conn, %{"id" => id}) do
    send_notification_to_panelist(id)
    send_notification_to_other_panelist(id)
    Repo.delete_all(from i in InterviewPanelist, where: i.id == ^id)
    send_resp(conn, :no_content, "")
  end

  defp send_notification_to_panelist(id) do
    {candidate_first_name, candidate_last_name, interview_name, panelist_login_name, start_time} =
      (from c in Candidate, join: i in assoc(c, :interviews), join: ip in assoc(i, :interview_panelist), join: it in assoc(i, :interview_type), where: ip.id == ^id, select: {c.first_name, c.last_name, it.name, ip.panelist_login_name, i.start_time}) |> Repo.one

    {:ok, interview_date} = Date.from(start_time) |> Timezone.convert("Asia/Kolkata") |> DateFormat.format("%b-%d", :strftime)
    email_content = Templates.panelist_removal_notification(true, candidate_first_name, candidate_last_name, interview_name, interview_date)
    send_mail_with_content(panelist_login_name, email_content)
  end

  defp send_notification_to_other_panelist(id) do
    interview_id = Repo.get(InterviewPanelist, id).interview_id
    other_panelist = (from c in Candidate, join: i in assoc(c, :interviews), join: ip in assoc(i, :interview_panelist), join: it in assoc(i, :interview_type), where: ip.id != ^id and ip.interview_id == ^interview_id, select: {c.first_name, c.last_name, it.name, ip.panelist_login_name, i.start_time}) |> Repo.one
    if(!is_nil(other_panelist)) do
      {candidate_first_name, candidate_last_name, interview_name, panelist_login_name, start_time} = other_panelist
      {:ok, interview_date} = Date.from(start_time) |> Timezone.convert("Asia/Kolkata") |> DateFormat.format("%b-%d", :strftime)
      email_content = Templates.panelist_removal_notification(false, candidate_first_name, candidate_last_name, interview_name, interview_date)
      send_mail_with_content(panelist_login_name, email_content)
    end
  end

  defp send_mail_with_content(panelist_login_name, email_content) do
    MailHelper.deliver(%{
      subject: "[RecruitX] Change in interview panel",
      to: [panelist_login_name |> InterviewPanelist.get_email_address],
      html_body: email_content
    })
  end
end
