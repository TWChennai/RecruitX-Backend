defmodule RecruitxBackend.Repo.Migrations.CreateSlotPanelist do
  use Ecto.Migration

  def change do
    create table(:slot_panelists) do
      add :panelist_login_name, :string, null: false
      add :slot_id, references(:slots, on_delete: :delete_all), null: false
      add :satisfied_criteria, :string

      timestamps()
    end

    create index(:slot_panelists, [:panelist_login_name, :slot_id], unique: true, name: :slot_panelist_login_name_index)
    create index(:slot_panelists, [:panelist_login_name])
    create index(:slot_panelists, [:slot_id])

    execute "create OR replace function check_slot_validity() returns trigger as $check_valid$
      begin
      IF EXISTS (select 1 from slot_panelists ip where ip.slot_id = NEW.slot_id group by ip.slot_id having count(ip.slot_id)>=2) THEN
      raise exception 'More than 2 sign-ups not allowed';
      END IF;
      RETURN NEW;
      end;
      $check_valid$ language plpgsql;"

    execute "create trigger slot_signup_validity before insert or update on slot_panelists for each row execute procedure check_slot_validity();"
  end
end
