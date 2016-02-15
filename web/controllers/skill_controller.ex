defmodule RecruitxBackend.SkillController do
  use RecruitxBackend.Web, :controller

  alias RecruitxBackend.Skill

  # TODO: Uncomment if/when implementing the create/update actions
  # plug :scrub_params, "skill" when action in [:create, :update]

  def index(conn, _params) do
    skills = Skill |> Repo.all
    conn |> render("index.json", skills: skills)
  end

  # def create(conn, %{"skill" => skill_params}) do
  #   changeset = Skill.changeset(%Skill{}, skill_params)
  #
  #   # case Repo.insert(changeset) do
  #   #   {:ok, skill} ->
  #   #     conn
  #   #     |> put_status(:created)
  #   #     |> put_resp_header("location", skill_path(conn, :show, skill))
  #   #     # |> render("show.json", skill: skill)
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
  # TODO: Handle error scenario of 'Repo.get!' - ie when an invalid/missing record is hit
  #   skill = Repo.get!(Skill, id)
  #   render(conn, "show.json", skill: skill)
  # end
  #
  # def update(conn, %{"id" => id, "skill" => skill_params}) do
  #   skill = Repo.get!(Skill, id)
  #   changeset = Skill.changeset(skill, skill_params)
  #
  #   case Repo.update(changeset) do
  #     {:ok, skill} ->
  #       render(conn, "show.json", skill: skill)
  #     {:error, changeset} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(RecruitxBackend.ChangesetView, "error.json", changeset: changeset)
  #   end
  # end
  #
  # def delete(conn, %{"id" => id}) do
  #   skill = Repo.get!(Skill, id)
  #
  #   # Here we use delete! (with a bang) because we expect
  #   # it to always work (and if it does not, it will raise).
  #   Repo.delete!(skill)
  #
  #   send_resp(conn, :no_content, "")
  # end
end
