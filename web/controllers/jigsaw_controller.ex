defmodule RecruitxBackend.JigsawController do
  use RecruitxBackend.Web, :controller

  alias Poison.Parser
  alias Timex.Date
  alias RecruitxBackend.Role

  @recruitment_department "People Recruiting"
  @office_princinpal Role.office_principal
  @time_out_error "Jigsaw API failed to respond, please try again later"
  @ops Role.ops
  @psm "Mgr"
  @people "People"
  @specialist "Specialist"
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
    # {experience, id} = parse_experience(id) #for_uat
    other_role = Role.retrieve_by_name(Role.other)
    recruiter_role = Map.merge(other_role, %{name: "Specialist"})
    user_details = case id do
      # "ppanelist" -> %{is_recruiter: false, calculated_hire_date: Date.now |> Date.shift(months: -12), past_experience: experience, role: Role.retrieve_by_name(Role.dev), is_super_user: false} #for_uat
      # "ppanelistp" -> %{is_recruiter: false, calculated_hire_date: Date.now |> Date.shift(months: -18), past_experience: experience, role: Role.retrieve_by_name(Role.qa), is_super_user: false} #for_uat
      # "rrecruitx" -> %{is_recruiter: true, calculated_hire_date: Date.now |> Date.shift(months: -12), past_experience: experience, role: recruiter_role, is_super_user: false} #for_uat
      # "rrecruitxr" -> %{is_recruiter: true, calculated_hire_date: Date.now |> Date.shift(months: -18), past_experience: experience, role: recruiter_role, is_super_user: false} #for_uat
      _  -> response = get_data_safely(id)
        case response.status_code do
          200 -> case response.body |> Parser.parse do
                      {:ok, %{"department" => %{"name" => department_name}, "role" => %{"name" => role_name}, "twExperience" => tw_experience, "totalExperience" => total_experience}} ->
                                      role = Role.retrieve_by_name(role_name)
                                      if is_nil(role), do: role = Map.merge(other_role, %{name: role_name})
                                      past_experience = Decimal.new(total_experience - tw_experience)
                                                       |> Decimal.round(2)
                                      tw_experience_in_month = tw_experience |> year_to_month
                                      calculated_hire_date = Date.now
                                                            |> Date.shift(months: -tw_experience_in_month)

                                      is_super_user = case role_name do
                                        @office_princinpal -> true
                                        @psm -> true
                                        @specialist -> case department_name do
                                          @people -> true #PC
                                          _ -> false
                                        end
                                        _ -> false
                                      end

                                      if is_super_user, do: role = Role.retrieve_by_name(@ops)

                                      case department_name do
                                        @recruitment_department -> %{is_recruiter: true, calculated_hire_date: calculated_hire_date, past_experience: past_experience, role: role, is_super_user: is_super_user, error: ""}

                                        _ -> %{is_recruiter: false, calculated_hire_date: calculated_hire_date, past_experience: past_experience, role: role, is_super_user: is_super_user, error: ""}
                                      end
                      {:error, reason} -> %{is_recruiter: false, calculated_hire_date: Date.now, past_experience: 0, role: other_role, error: reason}
                    end   #end of Parser stmt
            408 -> %{is_recruiter: false, calculated_hire_date: Date.now, past_experience: 0, role: other_role, is_super_user: false, error: @time_out_error}
            _ -> %{is_recruiter: false, calculated_hire_date: Date.now, past_experience: 0, role: other_role, is_super_user: false, error: @invalid_user}
      end #end of response status_code
    end   # end of user_details case stmt
    %{user_details: user_details}
  end

  defp get_data_safely(id) do
    try do
      HTTPotion.get("#{@jigsaw_url}#{id}", [headers: ["Authorization": @token]])
    rescue
      HTTPotion.HTTPError -> %{status_code: 408} #timeout
      _ -> %{status_code: 400}
    end
  end

  defp parse_experience(id) do
    result = Float.parse(id)
    if result != :error, do: result, else: {1.5, id}
  end

  defp year_to_month(experience) do
    round(experience * 12)
  end
end
