defmodule RecruitxBackend.SlotControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.SlotController

  alias RecruitxBackend.SlotCancellationNotification
  alias RecruitxBackend.TimexHelper

  let :post_parameters, do: Map.merge(convertKeysFromAtomsToStrings(%{count: 1}), convertKeysFromAtomsToStrings(params_with_assocs(:slot)))
  let :created_slot, do: insert(:slot)

  describe "create" do
    context "valid params" do
      before do: allow Repo |> to(accept(:insert, fn(_) -> {:ok, created_slot()} end))
      it "should return 201 and be successful" do
        insert(:interview, start_time: get_start_of_next_week(), interview_type: build(:interview_type, priority: 1))
        post_parameters = Map.put(post_parameters(), "start_time", get_start_of_next_week() |> TimexHelper.add(5, :hours))
        conn = action(:create, %{"slot" => post_parameters})

        conn |> should(be_successful())
        conn |> should(have_http_status(:created))
      end
    end

    context "invalid params" do
      it "returns error when role_id is empty" do
        response = action(:create, %{"slot" => Map.delete(post_parameters(), "role_id")})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expectedErrorReason =  %{"errors" => %{"role_id" => ["can't be blank"]}}
        expect(parsed_response) |> to(be(expectedErrorReason))
      end

      it "returns error when interview_type_id is empty" do
        response = action(:create, %{"slot" => Map.delete(post_parameters(), "interview_type_id")})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expectedErrorReason =  %{"errors" => %{"interview_type_id" => ["can't be blank"]}}
        expect(parsed_response) |> to(be(expectedErrorReason))
      end

      it "returns error when start_time is empty" do
        response = action(:create, %{"slot" => Map.delete(post_parameters(), "start_time")})
        response |> should(have_http_status(:unprocessable_entity))
        parsed_response = response.resp_body |> Poison.Parser.parse!
        expectedErrorReason =  %{"errors" => %{"start_time" => ["can't be blank"]}}
        expect(parsed_response) |> to(be(expectedErrorReason))
      end
    end
  end

  describe "delete" do
    before do: allow Repo |> to(accept(:get!, fn(_) -> {:ok, created_slot()} end))
    before do: allow Repo |> to(accept(:delete!, fn(_) -> {:ok, created_slot()} end))
    before do: allow SlotCancellationNotification |> to(accept(:execute, fn(_) -> :ok end))

    it "should return 200 and be successful" do
      conn = action(:delete, %{"id" => created_slot().id})

      conn |> should(be_successful())
      conn |> should(have_http_status(:no_content))
    end
  end
end
