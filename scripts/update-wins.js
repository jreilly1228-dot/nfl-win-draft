// Pulls each team's current win total from ESPN's public (unofficial) API
// and writes it into the Supabase `teams` table.
//
// Run manually with:  node scripts/update-wins.js
// Requires env vars: SUPABASE_URL, SUPABASE_SERVICE_KEY

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_KEY env vars.');
  process.exit(1);
}

async function main() {
  // 1. Get every NFL team's ESPN id + abbreviation
  const teamsRes = await fetch('https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams?limit=32');
  const teamsJson = await teamsRes.json();
  const espnTeams = teamsJson.sports[0].leagues[0].teams.map(t => ({
    id: t.team.id,
    abbr: t.team.abbreviation,
  }));

  const updates = [];

  // 2. For each team, look up its current record
  for (const t of espnTeams) {
    try {
      const res = await fetch(`https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/${t.id}`);
      const json = await res.json();
      const items = json.team?.record?.items || [];
      const overall = items.find(i => i.type === 'total') || items[0];
      const summary = overall?.summary || '0-0'; // format "W-L" or "W-L-T"
      const wins = parseInt(summary.split('-')[0], 10) || 0;
      updates.push({ abbr: t.abbr, wins });
    } catch (err) {
      console.error(`Failed to fetch record for ${t.abbr}:`, err.message);
    }
  }

  console.log('Fetched records:', updates);

  // 3. Write each team's win count into Supabase via its REST API
  for (const u of updates) {
    const resp = await fetch(`${SUPABASE_URL}/rest/v1/teams?id=eq.${u.abbr}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        apikey: SUPABASE_SERVICE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
        Prefer: 'return=minimal',
      },
      body: JSON.stringify({ wins: u.wins }),
    });
    if (!resp.ok) {
      console.error(`Failed to update ${u.abbr}: ${resp.status} ${await resp.text()}`);
    }
  }

  console.log('Done.');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
