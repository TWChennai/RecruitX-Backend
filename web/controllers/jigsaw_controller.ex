defmodule RecruitxBackend.JigsawController do
  use RecruitxBackend.Web, :controller

  alias Poison.Parser
  alias Timex.Date

  @recruitment_department "People Recruiting"
  @invalid_user "not a valid user"
  @jigsaw_url System.get_env("JIGSAW_URL")
  @token System.get_env("JIGSAW_TOKEN")

  @lint [{Credo.Check.Refactor.ABCSize, false}, {Credo.Check.Refactor.CyclomaticComplexity, false}]
  def show(conn, %{"id" => id}) do
    {experience, id} = parse_experience(id)
    user_details = case id do
      "ppanelist" -> %{is_recruiter: false, calculated_hire_date: Date.now |> Date.shift(months: -12), past_experience: experience}
      "ppanelistp" -> %{is_recruiter: false, calculated_hire_date: Date.now |> Date.shift(months: -18), past_experience: experience}
      "rrecruitx" -> %{is_recruiter: true, calculated_hire_date: Date.now |> Date.shift(months: -12), past_experience: experience}
      "rrecruitxr" -> %{is_recruiter: true, calculated_hire_date: Date.now |> Date.shift(months: -18), past_experience: experience}
      _  -> response = HTTPotion.get("#{@jigsaw_url}#{id}", [headers: ["Authorization": @token]])
        case response.body do
          "" -> %{is_recruiter: @invalid_user, calculated_hire_date: Date.now, past_experience: 0}
          _  -> case response.body |> Parser.parse do
                  {:ok, body} -> department = body["department"]
                                 tw_experience = body["twExperience"]
                                 total_experience = body["totalExperience"]
                                 past_experience = Decimal.new(total_experience - tw_experience)
                                                   |> Decimal.round(2)
                                 tw_experience_in_month = tw_experience |> year_to_month
                                 calculated_hire_date = Date.now
                                                        |> Date.shift(months: -tw_experience_in_month)
                  case department["name"] do
                    @recruitment_department -> %{is_recruiter: true, calculated_hire_date: calculated_hire_date, past_experience: past_experience}
                    _ -> %{is_recruiter: false, calculated_hire_date: calculated_hire_date, past_experience: past_experience}
                  end
                  {:error, reason} -> %{is_recruiter: reason, calculated_hire_date: Date.now, past_experience: 0}
                end
        end
    end

    conn |> render("show.json", user_details: user_details)
  end

  defp parse_experience(id) do
    result = Float.parse(id)
    if result != :error, do: result, else: {1.5, id}
  end

  defp year_to_month(experience) do
    trunc(experience * 12)
  end
end
