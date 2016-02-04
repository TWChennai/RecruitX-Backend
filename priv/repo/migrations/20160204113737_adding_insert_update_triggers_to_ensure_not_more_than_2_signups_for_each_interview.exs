defmodule RecruitxBackend.Repo.Migrations.AddingInsertUpdateTriggersToEnsureNotMoreThan_2SignupsForEachInterview do
  use Ecto.Migration

  def change do

    execute "create OR replace function check_validity() returns trigger as $check_valid$
    begin
    IF EXISTS (select 1 from interview_panelists ip where ip.interview_id = NEW.interview_id group by ip.interview_id having count(ip.interview_id)>=2) THEN
    raise exception 'More than 2 sign-ups not allowed';
    END IF;
    RETURN NEW;
    end;
    $check_valid$ language plpgsql;"

    execute "create trigger check_signup_validity before insert or update on interview_panelists for each row execute procedure check_validity();"
  end
end
