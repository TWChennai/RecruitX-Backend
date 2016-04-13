defmodule RecruitxBackend.PanelistController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.ChangesetView
  alias RecruitxBackend.Candidate
  alias MailmanExtensions.Templates
  alias MailmanExtensions.Mailer

  def create(conn, %{"interview_panelist" => post_params}) do
    interview_panelist_changeset = InterviewPanelist.changeset(%InterviewPanelist{}, post_params)
    case Repo.insert(interview_panelist_changeset) do
      {:ok, panelist} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", panelist_path(conn, :show, panelist))
        |> render("panelist.json", panelist: panelist)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(%{path_info: ["panelists", _]} = conn, %{"id" => id}) do
    Repo.delete_all(from i in InterviewPanelist, where: i.id == ^id)
    send_resp(conn, :no_content, "")
  end

  def delete(%{path_info: ["remove_panelists", _]} = conn, %{"id" => id}) do
    send_notification_to_panelist(id)
    Repo.delete_all(from i in InterviewPanelist, where: i.id == ^id)
    send_resp(conn, :no_content, "")
  end

  defp send_notification_to_panelist(id) do
    {candidate_first_name, candidate_last_name, interview_name, panelist_login_name} =
      (from c in Candidate, join: i in assoc(c, :interviews), join: ip in assoc(i, :interview_panelist), join: it in assoc(i, :interview_type), where: ip.id == ^id, select: {c.first_name, c.last_name, it.name, ip.panelist_login_name}) |> Repo.one

    email_content = Templates.panelist_removal_notification(candidate_first_name, candidate_last_name, interview_name)

    Mailer.deliver(%{
      subject: "[RecruitX] Update on the Interview for #{candidate_first_name} #{candidate_last_name}",
      to: panelist_login_name <> System.get_env("EMAIL_POSTFIX") |> String.split,
      html: email_content
    })
  end
end
