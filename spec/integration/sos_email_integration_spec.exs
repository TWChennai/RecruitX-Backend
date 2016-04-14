defmodule RecruitxBackend.SosEmailIntegrationSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.SosEmailController

  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias Timex.Date

  @moduletag :integration
  @endpoint RecruitxBackend.Endpoint

  describe "index" do
    it "should return sos_validity as false if there are no interviews with insufficient panelists" do
      Repo.delete_all InterviewPanelist
      Repo.delete_all Interview

      response = get conn_with_dummy_authorization(), "/sos_email", %{"get_status" => ""}

      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be(%{"sos_validity" => false}))
    end

    it "should return sos_validity as true when there are interviews with insufficient panelists" do
      Repo.delete_all InterviewPanelist
      Repo.delete_all Interview
      create(:interview, start_time: Date.now |> Date.shift(days: 1))

      response = get conn_with_dummy_authorization(), "/sos_email", %{"get_status" => ""}

      parsed_response = response.resp_body |> Poison.Parser.parse!
      expect(parsed_response) |> to(be(%{"sos_validity" => true}))
    end
  end
end
