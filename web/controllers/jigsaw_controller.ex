defmodule RecruitxBackend.JigsawController do
  use RecruitxBackend.Web, :controller

  alias Poison.Parser

  @recruitment_department "People Recruiting"
  @invalid_user "not a valid user"
  @jigsaw_url System.get_env("JIGSAW_URL")
  @token System.get_env("JIGSAW_TOKEN")

  @lint {Credo.Check.Refactor.CyclomaticComplexity, false}
  def show(conn, %{"id" => id}) do
    user_details = case id do
      "ppanelist" -> false
      "ppanelistp" -> false
      "rrecruitx" -> true
      "rrecruitxr" -> true
      _  -> response = HTTPotion.get("#{@jigsaw_url}#{id}", [headers: ["Authorization": @token]])
        case response.body do
          "" -> @invalid_user
          _  -> case response.body |> Parser.parse do
                  {:ok, body} -> department = body["department"]
                                  tw_hire_date = body["hireDate"]
                                  tw_experience = body["twExperience"]
                                  total_experience = body["totalExperience"]
                                  past_experience = Decimal.new(total_experience - tw_experience)
                                                    |> Decimal.round(2)
                  case department["name"] do
                    @recruitment_department -> %{is_recruiter: true, tw_hire_date: tw_hire_date, past_experience: past_experience}
                    _ -> %{is_recruiter: false, tw_hire_date: tw_hire_date, past_experience: past_experience}
                  end
                  {:error, reason} -> reason
                end
      end
    end

    conn |> render("show.json", user_details: user_details)
  end
end
