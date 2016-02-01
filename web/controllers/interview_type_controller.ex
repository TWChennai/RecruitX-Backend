defmodule RecruitxBackend.InterviewTypeController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.InterviewType

  # TODO: Uncomment if/when implementing the create/update actions
  # plug :scrub_params, "interview_type" when action in [:create, :update]

  def index(conn, _params) do
    interview_types = InterviewType |> InterviewType.default_order |> Repo.all
    json conn, interview_types
  end

  # def create(conn, %{"interview_type" => interview_params}) do
  #   changeset = InterviewType.changeset(%InterviewType{}, interview_params)
  #
  #   # case Repo.insert(changeset) do
  #   #   {:ok, interview_type} ->
  #   #     conn
  #   #     |> put_status(:created)
  #   #     |> put_resp_header("location", interview_path(conn, :show, interview_type))
  #   #     # |> render("show.json", interview_type: interview_type)
  #   #   {:error, changeset} ->
  #   #     conn
  #   #     |> put_status(:unprocessable_entity)
  #   #     # |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
  #   # end
  #   if changeset.valid? do
  #     Repo.insert(changeset)
  #     # TODO: Need to send JSON response
  #     send_resp(conn, 200, "")
  #   else
  #     # TODO: Need to send JSON response
  #     send_resp(conn, 400, "")
  #   end
  # end

  # def show(conn, %{"id" => id}) do
  #   interview_type = Repo.get!(InterviewType, id)
  #   render(conn, "show.json", interview_type: interview_type)
  # end
  #
  # def update(conn, %{"id" => id, "interview_type" => interview_params}) do
  #   interview_type = Repo.get!(InterviewType, id)
  #   changeset = InterviewType.changeset(interview_type, interview_params)
  #
  #   case Repo.update(changeset) do
  #     {:ok, interview_type} ->
  #       render(conn, "show.json", interview_type: interview_type)
  #     {:error, changeset} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
  #   end
  # end
  #
  # def delete(conn, %{"id" => id}) do
  #   interview_type = Repo.get!(InterviewType, id)
  #
  #   # Here we use delete! (with a bang) because we expect
  #   # it to always work (and if it does not, it will raise).
  #   Repo.delete!(interview_type)
  #
  #   send_resp(conn, :no_content, "")
  # end
end
