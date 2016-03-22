defmodule RecruitxBackend.PanelistControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.PanelistController

  let :post_parameters, do: convertKeysFromAtomsToStrings(Map.merge(fields_for(:interview_panelist), %{panelist_experience: 2}))

  describe "create" do
    let :interview_panelist, do: create(:interview_panelist)

    context "valid params" do
      before do: allow Repo |> to(accept(:insert, fn(_) -> {:ok, interview_panelist} end))

      it "should return 201 and be successful" do
        conn = action(:create, %{"interview_panelist" => post_parameters})

        conn |> should(be_successful)
        conn |> should(have_http_status(:created))
      end
    end

    context "invalid changeset due to constraints on insertion to database" do
      before do: allow Repo |> to(accept(:insert, fn(_) -> {:error, %Ecto.Changeset{ errors: [test: "does not exist"]}} end))
      #TODO: Find a way to fix this
      xit "should return 422(Unprocessable entity) and the reason" do
        response = action(:create, %{"interview_panelist" => post_parameters})
        response |> should(have_http_status(:unprocessable_entity))
        expect(response.resp_body) |> to(be(""))
      end
    end

    context "invalid params" do
      it "returns error when panelist_login_name is not given" do
        response = action(:create, %{"interview_panelist" => Map.delete(post_parameters, "panelist_login_name")})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expect(parsed_response) |> to(be(%{"errors" => %{"panelist_login_name" => ["can't be blank"]}}))
      end

      it "returns error when interview_id is not given" do
        response = action(:create, %{"interview_panelist" => Map.delete(post_parameters, "interview_id")})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expect(parsed_response) |> to(be(%{"errors" => %{"interview_id" => ["can't be blank"]}}))
      end

      it "returns error when panelist_login_name is invalid" do
        response = action(:create, %{"interview_panelist" => Map.merge(post_parameters, %{"panelist_login_name" => "1test"})})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expect(parsed_response) |> to(be(%{"errors" => %{"panelist_login_name" => ["has invalid format"]}}))
      end

      it "returns error when interview_id is invalid" do
        response = action(:create, %{"interview_panelist" => Map.merge(post_parameters, %{"interview_id" => "1test"})})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expect(parsed_response) |> to(be(%{"errors" => %{"interview_id" => ["is invalid"]}}))
      end
    end
  end
end
