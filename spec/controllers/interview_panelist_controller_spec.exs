defmodule RecruitxBackend.InterviewPanelistControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.InterviewPanelistController

  let :post_parameters, do: convertKeysFromAtomsToStrings(fields_for(:interview_panelist))

  describe "create" do
    let :interview_panelist, do: create(:interview_panelist)

    describe "valid params" do
      before do: allow Repo |> to(accept(:insert, fn(_) -> {:ok, interview_panelist} end))

      it "should return 201 and be successful" do
        conn = action(:create, %{"interview_panelist" => post_parameters})

        conn |> should(be_successful)
        conn |> should(have_http_status(:created))
        List.keyfind(conn.resp_headers, "location", 0) |> should(be({"location", "/interview_panelists/#{interview_panelist.id}"}))
      end
    end
  end

  def convertKeysFromAtomsToStrings(input) do
    for {key, val} <- input, into: %{}, do: {to_string(key), val}
  end
end
