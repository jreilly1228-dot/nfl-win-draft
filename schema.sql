-- Run this once in Supabase: Project → SQL Editor → New query → paste → Run

create table teams (
  id text primary key,              -- team abbreviation, e.g. 'BUF'
  name text not null,
  conference text not null,         -- 'AFC' | 'NFC'
  division text not null,           -- 'East' | 'North' | 'South' | 'West'
  line numeric not null,            -- preseason win total
  drafter smallint,                 -- 0, 1, 2, or null (undrafted)
  side text,                        -- 'over' | 'under' | null
  wins integer not null default 0,
  updated_at timestamptz default now()
);

create table draft_meta (
  id int primary key default 1,
  drafter_names text[] not null default array['Player 1','Player 2','Player 3'],
  week integer not null default 1,
  draft_locked boolean not null default false,
  updated_at timestamptz default now()
);
insert into draft_meta (id) values (1);

-- Once draft_locked is true, no one can change who owns a team or which
-- side (over/under) they took — even if they edit the database directly.
-- Weekly win totals stay editable regardless, since those need to keep updating.
create or replace function prevent_pick_edits_after_lock()
returns trigger as $$
declare
  locked boolean;
begin
  select draft_locked into locked from draft_meta where id = 1;
  if locked and (new.drafter is distinct from old.drafter or new.side is distinct from old.side) then
    raise exception 'Draft is locked — picks can no longer be changed.';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger lock_draft_picks
before update on teams
for each row execute function prevent_pick_edits_after_lock();

-- Open access for a small trusted group (no login required).
-- Anyone with your site's URL can view AND edit. Fine for 3 friends;
-- don't post the link publicly.
alter table teams enable row level security;
alter table draft_meta enable row level security;

create policy "public read teams" on teams for select using (true);
create policy "public write teams" on teams for update using (true) with check (true);

create policy "public read meta" on draft_meta for select using (true);
create policy "public write meta" on draft_meta for update using (true) with check (true);

-- Turns on live sync: when one person edits, everyone else's page updates instantly.
alter publication supabase_realtime add table teams;
alter publication supabase_realtime add table draft_meta;

-- Seed all 32 teams with DraftKings win-total lines (late Aug 2026).
insert into teams (id, name, conference, division, line) values
('BUF','Buffalo Bills','AFC','East',10.5),
('MIA','Miami Dolphins','AFC','East',4.5),
('NE','New England Patriots','AFC','East',10.5),
('NYJ','New York Jets','AFC','East',5.5),
('BAL','Baltimore Ravens','AFC','North',11.5),
('CIN','Cincinnati Bengals','AFC','North',10.5),
('CLE','Cleveland Browns','AFC','North',5.5),
('PIT','Pittsburgh Steelers','AFC','North',8.5),
('HOU','Houston Texans','AFC','South',9.5),
('IND','Indianapolis Colts','AFC','South',7.5),
('JAX','Jacksonville Jaguars','AFC','South',8.5),
('TEN','Tennessee Titans','AFC','South',6.5),
('DEN','Denver Broncos','AFC','West',9.5),
('KC','Kansas City Chiefs','AFC','West',10.5),
('LV','Las Vegas Raiders','AFC','West',5.5),
('LAC','Los Angeles Chargers','AFC','West',9.5),
('DAL','Dallas Cowboys','NFC','East',9.5),
('PHI','Philadelphia Eagles','NFC','East',10.5),
('NYG','New York Giants','NFC','East',7.5),
('WAS','Washington Commanders','NFC','East',7.5),
('CHI','Chicago Bears','NFC','North',9.5),
('DET','Detroit Lions','NFC','North',10.5),
('GB','Green Bay Packers','NFC','North',9.5),
('MIN','Minnesota Vikings','NFC','North',8.5),
('ATL','Atlanta Falcons','NFC','South',6.5),
('CAR','Carolina Panthers','NFC','South',7.5),
('NO','New Orleans Saints','NFC','South',7.5),
('TB','Tampa Bay Buccaneers','NFC','South',8.5),
('ARI','Arizona Cardinals','NFC','West',3.5),
('LAR','Los Angeles Rams','NFC','West',11.5),
('SF','San Francisco 49ers','NFC','West',9.5),
('SEA','Seattle Seahawks','NFC','West',10.5);
