defmodule RecruitxBackend.JigsawController do
  use RecruitxBackend.Web, :controller

  alias Poison.Parser
  alias Timex.Date
  alias RecruitxBackend.Role

  @recruitment_department "People Recruiting"
  @office_princinple "Off Prin"
  @operations "Operations"
  @people "People"
  @invalid_user "not a valid user"
  @jigsaw_url System.get_env("JIGSAW_URL")
  @token System.get_env("JIGSAW_TOKEN")

  # TODO: Use of dummy data (for dev/testing) in production-deployable code. Use some kind of interfaces to separate out the implementations
  def show(conn, %{"id" => id}) do
    %{user_details: user_details} = get_jigsaw_data(id)
    conn |> render("show.json", user_details: user_details)
  end

  @lint [{Credo.Check.Refactor.ABCSize, false}, {Credo.Check.Refactor.CyclomaticComplexity, false}]
  def get_jigsaw_data(id) do
    {experience, id} = parse_experience(id)
    other_role = Role.retrieve_by_name(Role.other)
    recruiter_role = Map.merge(other_role, %{name: "Specialist"})
    user_details = case id do
      "ppanelist" -> %{is_recruiter: false, calculated_hire_date: Date.now |> Date.shift(months: -12), past_experience: experience, role: Role.retrieve_by_name(Role.dev), is_super_user: false}
      "ppanelistp" -> %{is_recruiter: false, calculated_hire_date: Date.now |> Date.shift(months: -18), past_experience: experience, role: Role.retrieve_by_name(Role.qa), is_super_user: false}
      "rrecruitx" -> %{is_recruiter: true, calculated_hire_date: Date.now |> Date.shift(months: -12), past_experience: experience, role: recruiter_role, is_super_user: false}
      "rrecruitxr" -> %{is_recruiter: true, calculated_hire_date: Date.now |> Date.shift(months: -18), past_experience: experience, role: recruiter_role, is_super_user: false}
      _  -> response = HTTPotion.get("#{@jigsaw_url}#{id}", [headers: ["Authorization": @token]])
        case response.body do
          "" -> %{is_recruiter: @invalid_user, calculated_hire_date: Date.now, past_experience: 0}
          _  -> case response.body |> Parser.parse do
                  {:ok, %{"department" => %{"name" => department_name}, "role" => %{"name" => role_name}, "twExperience" => tw_experience, "totalExperience" => total_experience}} ->
                                  role = Role.retrieve_by_name(role_name)
                                  if is_nil(role), do: role = Map.merge(other_role, %{name: role_name})
                                  past_experience = Decimal.new(total_experience - tw_experience)
                                                   |> Decimal.round(2)
                                  tw_experience_in_month = tw_experience |> year_to_month
                                  calculated_hire_date = Date.now
                                                        |> Date.shift(months: -tw_experience_in_month)


                                  is_super_user = case role_name do
                                    @office_princinple -> true
                                    @operations -> true
                                    @people -> true
                                    _ -> false
                                  end

                                  case department_name do
                                    @recruitment_department -> %{is_recruiter: true, calculated_hire_date: calculated_hire_date, past_experience: past_experience, role: role, is_super_user: is_super_user}

                                    _ -> %{is_recruiter: false, calculated_hire_date: calculated_hire_date, past_experience: past_experience, role: role, is_super_user: is_super_user}
                                  end
                  {:error, reason} -> %{is_recruiter: reason, calculated_hire_date: Date.now, past_experience: 0, role: other_role}
                end   # end of Parser stmt
        end   # end of response.body case stmt
    end   # end of user_details case stmt
    %{user_details: user_details}
  end

  defp parse_experience(id) do
    result = Float.parse(id)
    if result != :error, do: result, else: {1.5, id}
  end

  defp year_to_month(experience) do
    round(experience * 12)
  end
end
