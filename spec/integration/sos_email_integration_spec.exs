defmodule RecruitxBackend.SosEmailIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.SosEmailController

  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.TimexHelper

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint

  before do: Enum.each([InterviewPanelist, Interview], &Repo.delete_all/1)

  describe "index" do
    it "should return sos_validity as false if there are no interviews with insufficient panelists" do
      response = get conn_with_dummy_authorization(), "/sos_email", %{"get_status" => ""}

      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be(%{"sos_validity" => false}))
    end

    it "should return sos_validity as true when there are interviews with insufficient panelists" do
      insert(:interview, start_time: TimexHelper.utc_now() |> TimexHelper.add(1, :days))

      response = get conn_with_dummy_authorization(), "/sos_email", %{"get_status" => ""}

      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be(%{"sos_validity" => true}))
    end
  end
end
