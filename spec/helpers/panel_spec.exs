defmodule PanelSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Panel

  alias RecruitxBackend.Repo
  alias RecruitxBackend.Interview
  alias RecruitxBackend.InterviewPanelist
  alias RecruitxBackend.Panel
  alias RecruitxBackend.SlotPanelist
  alias Ecto.Changeset
  alias Timex.Date

  describe "methods" do
    context "default_order" do
      before do: Repo.delete_all(Interview)

      it "should sort by ascending order of start time" do
        now = Date.now
        interview_with_start_date1 = create(:interview, start_time: now |> Date.shift(days: 1))
        interview_with_start_date2 = create(:interview, start_time: now |> Date.shift(days: 3))
        interview_with_start_date3 = create(:interview, start_time: now |> Date.shift(days: -2))
        interview_with_start_date4 = create(:interview, start_time: now |> Date.shift(days: -5))

        [interview1, interview2, interview3, interview4] = Interview |> Panel.default_order |> Repo.all

        expect(interview1.start_time) |> to(eq(interview_with_start_date4.start_time))
        expect(interview2.start_time) |> to(eq(interview_with_start_date3.start_time))
        expect(interview3.start_time) |> to(eq(interview_with_start_date1.start_time))
        expect(interview4.start_time) |> to(eq(interview_with_start_date2.start_time))
      end

      it "should tie-break on id for the same start time" do
        now = Date.now
        interview_with_start_date1 = create(:interview, start_time: now |> Date.shift(days: 1), id: 1)
        interview_with_same_start_date1 = create(:interview, start_time: now |> Date.shift(days: 1), id: interview_with_start_date1.id + 1)
        interview_with_start_date2 = create(:interview, start_time: now |> Date.shift(days: 2))

        [interview1, interview2, interview3] = Interview |> Panel.default_order |> Repo.all

        expect(interview1.start_time) |> to(eq(interview_with_start_date1.start_time))
        expect(interview2.start_time) |> to(eq(interview_with_same_start_date1.start_time))
        expect(interview3.start_time) |> to(eq(interview_with_start_date2.start_time))
      end
    end

    context "get the interviews in the next 7 days" do
      it "should return the interview from the next 7 days" do
        Repo.delete_all(Interview)
        create(:interview, id: 900, start_time: Date.now |> Date.shift(days: +8))
        create(:interview, id: 901, start_time: Date.now |> Date.shift(days: -6))
        create(:interview, id: 902, start_time: Date.now |> Date.shift(days: +1))

        actual_result = Interview |> Panel.now_or_in_next_seven_days |> Repo.one

        expect(actual_result.id) |> to(be(902))
      end
    end

    context "validate_panelist_experience" do
      let :valid_params, do: fields_for(:interview_panelist)
      it "should not add error if incoming changeset has error" do
        invalid_changeset = Changeset.cast(%InterviewPanelist{}, Map.delete(valid_params, :panelist_login_name), ~w(panelist_login_name interview_id), ~w())
        %{valid?: validity, errors: errors} = Panel.validate_panelist_experience(invalid_changeset, nil)

        expect(validity) |> to(be(false))
        expect(errors) |> to(be([panelist_login_name: "can't be blank"]))
      end

      it "should not add error if incoming changeset has no error and panelist_experience is not there" do
        invalid_changeset = Changeset.cast(%InterviewPanelist{}, valid_params, ~w(panelist_login_name interview_id), ~w())
        %{valid?: validity, errors: errors} = Panel.validate_panelist_experience(invalid_changeset, nil)

        expect(validity) |> to(be(false))
        expect(errors) |> to(be([panelist_experience: "can't be blank"]))
      end

      it "should not add error if incoming changeset has no error and panelist_login_name is panelist_experience is there" do
        invalid_changeset = Changeset.cast(%InterviewPanelist{}, valid_params, ~w(panelist_login_name interview_id), ~w())
        %{valid?: validity, errors: errors} = Panel.validate_panelist_experience(invalid_changeset, 1)

        expect(validity) |> to(be(true))
        expect(errors) |> to(be([]))
      end
    end

    context "validate_panelist_role" do
      let :valid_params, do: fields_for(:interview_panelist)
      it "should not add error if incoming changeset has error" do
        invalid_changeset = Changeset.cast(%InterviewPanelist{}, Map.delete(valid_params, :panelist_login_name), ~w(panelist_login_name interview_id), ~w())
        %{valid?: validity, errors: errors} = Panel.validate_panelist_role(invalid_changeset, nil)

        expect(validity) |> to(be(false))
        expect(errors) |> to(be([panelist_login_name: "can't be blank"]))
      end

      it "should not add error if incoming changeset has no error and panelist_experience is not there" do
        valid_changeset = Changeset.cast(%InterviewPanelist{}, valid_params, ~w(panelist_login_name interview_id), ~w())
        %{valid?: validity, errors: errors} = Panel.validate_panelist_role(valid_changeset, nil)

        expect(validity) |> to(be(false))
        expect(errors) |> to(be([panelist_role: "can't be blank"]))
      end

      it "should not add error if incoming changeset has no error and panelist_login_name is panelist_experience is there" do
        invalid_changeset = Changeset.cast(%InterviewPanelist{}, valid_params, ~w(panelist_login_name interview_id), ~w())
        %{valid?: validity, errors: errors} = Panel.validate_panelist_role(invalid_changeset, 1)

        expect(validity) |> to(be(true))
        expect(errors) |> to(be([]))
      end
    end

    context "get_start_times_interviewed_by" do
      it "should give only interview's start_time of a panelist if there are no slots for that panelist" do
        Repo.delete_all(InterviewPanelist)
        interview_panelist = create(:interview_panelist, panelist_login_name: "recruitx")
        interview_start_time = Repo.preload(interview_panelist, :interview).interview.start_time
        response = Panel.get_start_times_interviewed_by("recruitx")

        expect(response) |> to(be([interview_start_time]))
      end

      it "should give only slot's start_time of a panelist if there are no interviews for that panelist" do
        Repo.delete_all(SlotPanelist)
        slot_panelist = create(:slot_panelist, panelist_login_name: "recruitx")
        slot_start_time = Repo.preload(slot_panelist, :slot).slot.start_time
        response = Panel.get_start_times_interviewed_by("recruitx")

        expect(response) |> to(be([slot_start_time]))
      end

      it "should give both interview's and slot's start_time of a panelist" do
        Repo.delete_all(InterviewPanelist)
        Repo.delete_all(SlotPanelist)
        interview_panelist = create(:interview_panelist, panelist_login_name: "recruitx")
        slot_panelist = create(:slot_panelist, panelist_login_name: "recruitx")
        interview_start_time = Repo.preload(interview_panelist, :interview).interview.start_time
        slot_start_time = Repo.preload(slot_panelist, :slot).slot.start_time
        response = Panel.get_start_times_interviewed_by("recruitx")

        expect(response) |> to(be([interview_start_time, slot_start_time]))
      end
    end

    context "desc_order" do
      before do: Repo.delete_all(Interview)
      it "should sort by descending order of start time" do
        now = Date.now
        interview_with_start_date1 = create(:interview, start_time: now |> Date.shift(days: 1))
        interview_with_start_date2 = create(:interview, start_time: now |> Date.shift(days: 3))
        interview_with_start_date3 = create(:interview, start_time: now |> Date.shift(days: -2))
        interview_with_start_date4 = create(:interview, start_time: now |> Date.shift(days: -5))

        [interview1, interview2, interview3, interview4] = Interview |> Panel.descending_order |> Repo.all

        expect(interview1.start_time) |> to(eq(interview_with_start_date2.start_time))
        expect(interview2.start_time) |> to(eq(interview_with_start_date1.start_time))
        expect(interview3.start_time) |> to(eq(interview_with_start_date3.start_time))
        expect(interview4.start_time) |> to(eq(interview_with_start_date4.start_time))
      end

      it "should tie-break on id for the same start time" do
        now = Date.now
        interview_with_start_date1 = create(:interview, start_time: now |> Date.shift(days: 1), id: 1)
        interview_with_same_start_date1 = create(:interview, start_time: now |> Date.shift(days: 1), id: interview_with_start_date1.id + 1)
        interview_with_start_date2 = create(:interview, start_time: now |> Date.shift(days: 2))

        [interview1, interview2, interview3] = Interview |> Panel.descending_order |> Repo.all

        expect(interview1.start_time) |> to(eq(interview_with_start_date2.start_time))
        expect(interview2.start_time) |> to(eq(interview_with_same_start_date1.start_time))
        expect(interview3.start_time) |> to(eq(interview_with_start_date1.start_time))
      end
    end
  end
end
