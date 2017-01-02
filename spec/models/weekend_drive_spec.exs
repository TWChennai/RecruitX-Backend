defmodule RecruitxBackend.WeekendDriveSpec do
  use ESpec.Phoenix, model: RecruitxBackend.WeekendDrive

  alias RecruitxBackend.WeekendDrive
  alias Timex.Date

  let :valid_attrs, do: fields_for(:weekend_drive)
  let :invalid_attrs, do: %{}

  context "valid changeset" do
    subject do: WeekendDrive.changeset(%WeekendDrive{}, valid_attrs)

    it do: should be_valid

    it "should have a start date" do
      weekend_drive_without_start_date = Map.delete(valid_attrs, :start_date)
      changeset = WeekendDrive.changeset(%WeekendDrive{}, weekend_drive_without_start_date)
      expect(changeset) |> to_not(be_valid)
      expect(changeset) |> to(have_errors(start_date: "can't be blank"))
    end

    it "should have an end date" do
      weekend_drive_without_end_date = Map.delete(valid_attrs, :end_date)
      changeset = WeekendDrive.changeset(%WeekendDrive{}, weekend_drive_without_end_date)
      expect(changeset) |> to_not(be_valid)
      expect(changeset) |> to(have_errors(end_date: "can't be blank"))
    end

    it "should have the number of candidates specified" do
      weekend_drive_without_no_of_candidates = Map.delete(valid_attrs, :no_of_candidates)
      changeset = WeekendDrive.changeset(%WeekendDrive{}, weekend_drive_without_no_of_candidates)
      expect(changeset) |> to_not(be_valid)
      expect(changeset) |> to(have_errors(no_of_candidates: "can't be blank"))
    end

    it "can have the no of panelists unspecified" do
      weekend_drive_without_no_of_panelists = Map.delete(valid_attrs, :no_of_panelists)
      changeset = WeekendDrive.changeset(%WeekendDrive{}, weekend_drive_without_no_of_panelists)
      expect(changeset) |> to(be_valid)
    end

    it "should have a future start date" do
      weekend_drive_with_start_date_in_the_past = Map.merge(valid_attrs, %{start_date: Date.now |> Date.shift(days: -1)})
      changeset = WeekendDrive.changeset(%WeekendDrive{}, weekend_drive_with_start_date_in_the_past)
      expect(changeset) |> to_not(be_valid)
      expect(changeset) |> to(have_errors(start_date: "should be in the future"))
    end

    it "should have an end_date after start date" do
      weekend_drive_with_end_date_before_start_date = Map.merge(valid_attrs, %{end_date: Date.now |> Date.shift(days: -1)})
      changeset = WeekendDrive.changeset(%WeekendDrive{}, weekend_drive_with_end_date_before_start_date)
      expect(changeset) |> to_not(be_valid)
      expect(changeset) |> to(have_errors(end_date: "should be after start date"))
    end

    it "should have role mapped to weekend drive" do
       weekend_drive_without_role = Map.delete(valid_attrs, :role_id)
       changeset = WeekendDrive.changeset(%WeekendDrive{}, weekend_drive_without_role)
       expect(changeset) |> to_not(be_valid)
       expect(changeset) |> to(have_errors(role_id: "can't be blank"))
    end
  end
end
