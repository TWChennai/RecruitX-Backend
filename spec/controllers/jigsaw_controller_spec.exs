defmodule RecruitxBackend.JigsawControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.JigsawController

  alias RecruitxBackend.JigsawController
  alias RecruitxBackend.Role
  alias RecruitxBackend.TimexHelper

  @recruitment_department "People Recruiting"
  @office_princinpal Role.office_principal
  @psm "Mgr"
  @people "People"
  @specialist "Specialist"

  let :panelist_role, do: insert(:role)
  let :hire_date, do: TimexHelper.utc_now() |> TimexHelper.add(-5, :months) |> TimexHelper.format_with_timezone("%Y-%m-%d")

  describe "get_jigsaw_data" do
    it "should return details for normal users" do
      past_exp = 5.34
      jigsaw_result = %{body: "{\"role\":{\"name\":\"#{panelist_role().name}\"},\"department\":{\"name\":\"PS\"},
                              \"hireDate\":\"#{hire_date()}\",\"totalExperience\":12.84,\"twExperience\":#{past_exp}}", status_code: 200}
      allow HTTPotion |> to(accept(:get, fn(_, _) -> jigsaw_result end))
      %{user_details: %{is_recruiter: is_recruiter, calculated_hire_date: calculated_hire_date, past_experience: past_experience,
                                  role: role, is_super_user: is_super_user}} = JigsawController.get_jigsaw_data("")

      expect(is_recruiter) |> to(be(false))
      expect(is_super_user) |> to(be(false))
      expect(role) |> to(be(panelist_role()))
      expect(past_experience) |> to(be(Decimal.new(7.5)))
      expect(Timex.diff(calculated_hire_date, TimexHelper.utc_now() |> TimexHelper.add(-round(past_exp * 12), :months), :seconds)) |> to(be(0))
    end

    it "should return the is_recruiter true for recruiters" do
      jigsaw_result = %{body: "{\"role\":{\"name\":\"#{panelist_role().name}\"},\"department\":{\"name\":\"#{@recruitment_department}\"},
                              \"hireDate\":\"2011-05-05\",\"totalExperience\":12.84,\"twExperience\":5.34}", status_code: 200}
      allow HTTPotion |> to(accept(:get, fn(_, _) -> jigsaw_result end))
      %{user_details: %{is_recruiter: is_recruiter, calculated_hire_date: _calculated_hire_date,
                         is_super_user: is_super_user}} = JigsawController.get_jigsaw_data("")

      expect(is_recruiter) |> to(be(true))
      expect(is_super_user) |> to(be(false))
    end

    context "should return is_super_user true for Operations team" do
      it "for OfficePrincipals" do
        jigsaw_result = %{body: "{\"role\":{\"name\":\"#{@office_princinpal}\"},\"department\":{\"name\":\"PS\"},
                                \"hireDate\":\"2011-05-05\",\"totalExperience\":12.84,\"twExperience\":5.34}", status_code: 200}
        allow HTTPotion |> to(accept(:get, fn(_, _) -> jigsaw_result end))

        %{user_details: %{is_recruiter: is_recruiter, is_super_user: is_super_user}} = JigsawController.get_jigsaw_data("")

        expect(is_recruiter) |> to(be(false))
        expect(is_super_user) |> to(be(true))
      end

      it "for PSMs" do
        jigsaw_result = %{body: "{\"role\":{\"name\":\"#{@psm}\"},\"department\":{\"name\":\"PS\"},
                                \"hireDate\":\"2011-05-05\",\"totalExperience\":12.84,\"twExperience\":5.34}", status_code: 200}
        allow HTTPotion |> to(accept(:get, fn(_, _) -> jigsaw_result end))

        %{user_details: %{is_recruiter: is_recruiter, is_super_user: is_super_user}} = JigsawController.get_jigsaw_data("")

        expect(is_recruiter) |> to(be(false))
        expect(is_super_user) |> to(be(true))
      end

      it "for PCs" do
        jigsaw_result = %{body: "{\"role\":{\"name\":\"#{@specialist}\"},\"department\":{\"name\":\"#{@people}\"},
                                \"hireDate\":\"2011-05-05\",\"totalExperience\":12.84,\"twExperience\":5.34}", status_code: 200}
        allow HTTPotion |> to(accept(:get, fn(_, _) -> jigsaw_result end))

        %{user_details: %{is_recruiter: is_recruiter, is_super_user: is_super_user}} = JigsawController.get_jigsaw_data("")

        expect(is_recruiter) |> to(be(false))
        expect(is_super_user) |> to(be(true))
      end
    end
  end
end
