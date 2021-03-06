defmodule RecruitxBackend.TimerSpec do
  use ESpec.Phoenix, model: RecruitxBackend.Timer

  alias Ecto.Changeset
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Timer
  alias RecruitxBackend.TimexHelper
  alias Timex.Duration

  @duration_of_interview 1

  describe "methods" do
    let :valid_params, do: params_with_assocs(:interview)

    context "add_end_time" do
      it "should calculate and add end_time when incoming changeset is valid" do
        valid_changeset = Changeset.cast(%Interview{}, Map.delete(valid_params(), :end_time), ~w(candidate_id interview_type_id start_time interview_status_id))
        response = Timer.add_end_time(valid_changeset, @duration_of_interview)
        expect(response.changes.end_time) |> to(be(valid_params().start_time |> TimexHelper.add(1, :hours)))
      end

      it "should not calculate and add end_time when incoming changeset is valid" do
        invalid_changeset = Changeset.cast(%Interview{}, Map.delete(valid_params(), :end_time), ~w(candidate_id interview_type_id interview_status_id))
        response = Timer.add_end_time(invalid_changeset, @duration_of_interview)
        expect(fn -> response.changes.end_time end) |> to(raise_exception())
      end
    end

    context "is_in_future" do
      it "should validate and should not add error when incoming changeset's start_time is in future" do
        valid_changeset = Changeset.cast(%Interview{}, valid_params(), ~w(candidate_id interview_type_id start_time interview_status_id))
        response = Timer.is_in_future(valid_changeset, :start_time)
        expect(response.valid?) |> to(be(true))
      end

      it "should validate and should add error when incoming changeset's start_time is in future" do
        valid_params = Map.merge(Map.delete(valid_params(), :start_time), %{start_time: TimexHelper.utc_now() |> TimexHelper.add(-1, :hours)})
        valid_changeset = Changeset.cast(%Interview{}, valid_params, ~w(candidate_id interview_type_id start_time interview_status_id))
        response = Timer.is_in_future(valid_changeset, :start_time)
        expect(response.valid?) |> to(be(false))
        expect(response) |> to(have_errors(start_time: {"should be in the future", []}))
      end
    end

    context "get_current_week_weekdays" do
      it "should return from monday to friday of the current week" do
        %{starting: starting, ending: ending} = Timer.get_current_week_weekdays
        expect(starting) |> to(be(TimexHelper.beginning_of_week(TimexHelper.utc_now())))
        expect(ending) |> to(be(TimexHelper.end_of_week(TimexHelper.utc_now()) |> TimexHelper.add(-2, :days)))
      end
    end

    context "get_current_week" do
      it "should return from monday to sunday of the current week" do
        %{starting: starting, ending: ending} = Timer.get_current_week
        expect(TimexHelper.compare(starting, TimexHelper.beginning_of_week(TimexHelper.utc_now()))) |> to(be_true())
        expect(TimexHelper.compare(ending, TimexHelper.end_of_week(TimexHelper.utc_now()))) |> to(be_true())
      end
    end

    context "get_previous_week" do
      it "should return from monday to sunday of the previous week" do
        %{starting: starting, ending: ending} = Timer.get_previous_week
        some_day_in_previous_week = TimexHelper.utc_now() |> TimexHelper.beginning_of_week |> Timex.subtract(Duration.from_days(1))
        expect(TimexHelper.compare(starting, TimexHelper.beginning_of_week(some_day_in_previous_week))) |> to(be_true())
        expect(TimexHelper.compare(ending, TimexHelper.end_of_week(some_day_in_previous_week))) |> to(be_true())
      end
    end

    context "get_week_ranges" do
      it "should return current week range when requested count is one" do
        expect([]) |> to(be(Timer.get_week_ranges(0)))
        [%{starting: starting, ending: ending}] = Timer.get_week_ranges(1)
        expect(TimexHelper.compare(starting, TimexHelper.beginning_of_week(TimexHelper.utc_now()))) |> to(be_true())
        expect(TimexHelper.compare(ending, TimexHelper.end_of_week(TimexHelper.utc_now()))) |> to(be_true())

        [%{starting: starting1, ending: ending1},
          %{starting: starting2, ending: ending2}] = Timer.get_week_ranges(2)
          expect(TimexHelper.compare(starting1, TimexHelper.beginning_of_week(TimexHelper.utc_now()))) |> to(be_true())
          expect(TimexHelper.compare(ending1, TimexHelper.end_of_week(TimexHelper.utc_now()))) |> to(be_true())
          some_day_in_previous_week = Timex.subtract(TimexHelper.utc_now(), Duration.from_days(8))
          expect(TimexHelper.compare(starting2, TimexHelper.beginning_of_week(some_day_in_previous_week))) |> to(be_true())
          expect(TimexHelper.compare(ending2, TimexHelper.end_of_week(some_day_in_previous_week))) |> to(be_true())
      end
    end

    context "is_less_than_a_month" do
      it "should validate and should not add error when incoming changeset's start_time is less than a month" do
        valid_changeset = Changeset.cast(%Interview{}, valid_params(), ~w(candidate_id interview_type_id start_time interview_status_id))
        response = Timer.is_less_than_a_month(valid_changeset, :start_time)
        expect(response.valid?) |> to(be(true))
      end

      it "should validate and should add error when incoming changeset's start_time is after a month" do
        valid_params = Map.merge(Map.delete(valid_params(), :start_time), %{start_time: TimexHelper.utc_now() |> TimexHelper.add(2, :months)})
        valid_changeset = Changeset.cast(%Interview{}, valid_params, ~w(candidate_id interview_type_id start_time interview_status_id))
        response = Timer.is_less_than_a_month(valid_changeset, :start_time)
        expect(response.valid?) |> to(be(false))
        expect(response) |> to(have_errors(start_time: {"should be less than a month", []}))
      end
    end
  end
end
