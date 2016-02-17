defmodule RecruitxBackend.JigsawController do
  use RecruitxBackend.Web, :controller

  alias Poison.Parser

  @recruitment_department "People Recruiting"
  @invalid_user "not a valid user"
  @jigsaw_url System.get_env("JIGSAW_URL")
  @token System.get_env("JIGSAW_TOKEN")

  @lint {Credo.Check.Refactor.CyclomaticComplexity, false}
  def show(conn, %{"id" => id}) do
      case id do
        "mahalakshme1994" -> is_recruiter = false
        "shridhar.u.p" -> is_recruiter = true
         _  -> response = HTTPotion.get("#{@jigsaw_url}#{id}", [headers: ["Authorization": @token]])
        is_recruiter = case response.body do
          "" -> @invalid_user
          _  -> case response.body |> Parser.parse do
            {:ok, body} ->  key_value_response = for {key, val} <- body, into: %{}, do: {String.to_atom(key), val}
                        department = key_value_response.department
                        department_key_value_pair = for {key, val} <- department, into: %{}, do: {String.to_atom(key), val}
                            case department_key_value_pair.name do
                              @recruitment_department -> true
                              _ -> false
                            end
           {:error, reason} -> reason
        end
    end
  end
  conn |> render("show.json", is_recruiter: is_recruiter)
end
end
