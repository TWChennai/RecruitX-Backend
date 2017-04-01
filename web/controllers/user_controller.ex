defmodule RecruitxBackend.UserController do
  use RecruitxBackend.Web, :controller

  alias Poison.Parser
  alias RecruitxBackend.Role
  alias RecruitxBackend.SignupCop
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.TimexHelper

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
    {experience, id} = parse_experience(id) #for_uat
    other_role = Role.retrieve_by_name(Role.other)
    recruiter_role = Map.merge(other_role, %{name: "Specialist"})
    user_details = case id do
      "ppanelist" -> %{is_recruiter: false, calculated_hire_date: TimexHelper.utc_now() |> TimexHelper.add(-12, :months), past_experience: experience, role: Role.retrieve_by_name(Role.dev), is_super_user: false, error: nil, is_signup_cop: true} #for_uat
      "ppanelistp" -> %{is_recruiter: false, calculated_hire_date: TimexHelper.utc_now() |> TimexHelper.add(-18, :months), past_experience: experience, role: Role.retrieve_by_name(Role.qa), is_super_user: false, error: nil, is_signup_cop: false} #for_uat
      "rrecruitx" -> %{is_recruiter: true, calculated_hire_date: TimexHelper.utc_now() |> TimexHelper.add(-12, :months), past_experience: experience, role: recruiter_role, is_super_user: false, error: nil, is_signup_cop: false} #for_uat
      "rrecruitxr" -> %{is_recruiter: true, calculated_hire_date: TimexHelper.utc_now() |> TimexHelper.add(-18, :months), past_experience: experience, role: recruiter_role, is_super_user: false, error: nil, is_signup_cop: false} #for_uat
      _  -> response = get_data_safely("#{@jigsaw_url}/people/#{id}")
        case response.status_code do
          200 -> case response.body |> Parser.parse do
                      {:ok, %{"department" => %{"name" => department_name}, "role" => %{"name" => role_name}, "twExperience" => tw_experience, "totalExperience" => total_experience}} ->
                                      role = Role.retrieve_by_name(role_name) || Map.merge(other_role, %{name: role_name})
                                      past_experience = Decimal.new(total_experience - tw_experience)
                                                       |> Decimal.round(2)
                                      tw_experience_in_month = tw_experience |> year_to_month
                                      calculated_hire_date = TimexHelper.utc_now()
                                                            |> TimexHelper.add(-tw_experience_in_month, :months)

                                      is_super_user = case role_name do
                                        @office_princinpal -> true
                                        @psm -> true
                                        @specialist -> case department_name do
                                          @people -> true #PC
                                          _ -> false
                                        end
                                        _ -> false
                                      end

                                      role = if is_super_user, do: Role.retrieve_by_name(@ops), else: role

                                      case department_name do
                                        @recruitment_department -> %{is_recruiter: true, calculated_hire_date: calculated_hire_date, past_experience: past_experience, role: role, is_super_user: is_super_user, error: "", is_signup_cop: true}
                                        _ -> %{is_recruiter: false, calculated_hire_date: calculated_hire_date, past_experience: past_experience, role: role, is_super_user: is_super_user, error: "", is_signup_cop: SignupCop.is_signup_cop(id)}
                                      end
                      {:error, reason} -> %{is_recruiter: false, calculated_hire_date: TimexHelper.utc_now(), past_experience: 0, role: other_role, error: reason, is_signup_cop: false}
                    end   #end of Parser stmt
            408 -> %{is_recruiter: false, calculated_hire_date: TimexHelper.utc_now(), past_experience: 0, role: other_role, is_super_user: false, error: @time_out_error, is_signup_cop: false}
            _ -> %{is_recruiter: false, calculated_hire_date: TimexHelper.utc_now(), past_experience: 0, role: other_role, is_super_user: false, error: @invalid_user, is_signup_cop: false}
      end #end of response status_code
    end   # end of user_details case stmt
    %{user_details: user_details}
  end

  @lint [{Credo.Check.Readability.LargeNumbers, false}]
  def get_data_safely(url) do
    try do
      HTTPotion.get(url, [headers: ["Authorization": @token], timeout: 15_000])
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

  def is_valid_user(user_name) do
    has_signed_up_before = InterviewPanelist.has_signed_up_before(user_name)
    is_valid_twer = if !has_signed_up_before do
      %{user_details: user_details} = get_jigsaw_data(user_name)
      user_details.error == ""
    end
    has_signed_up_before || is_valid_twer
  end
end
