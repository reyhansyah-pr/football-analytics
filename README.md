# Premier League Analytics End-to-End Pipeline Project

A [dbt](https://www.getdbt.com/) project that transforms raw Premier League data (teams, matches, players, and managers) into an analytics-ready star schema for querying standings, results, and manager performance history.

## Overview

Data is ingested from a Premier League API and [List of Premier League managers](https://en.wikipedia.org/wiki/List_of_Premier_League_managers) into raw Postgres tables, then modeled through dbt into clean staging models and a set of dimension/fact tables optimized for reporting — season standings, home/away splits, manager tenure and streaks, squad rosters, and more.

**Warehouse:** Postgres (`premier_league_db`)
**Orchestration:** Containerized via Docker (`ghcr.io/dbt-labs/dbt-postgres:1.8`)

## Project Structure

```
models/
├── staging/          # Cleaned, deduplicated, typed source data (incremental)
│   ├── stg_matches
│   ├── stg_teams
│   ├── stg_team_squad
│   └── stg_manager
└── marts/            # Star-schema dimensions and facts (table materialized)
    ├── dim_teams
    ├── dim_season
    ├── dim_manager
    └── fact_*         # see below
```

## Data Sources

Raw tables live in `premier_league_db.raw`:

| Source table     | Description                     |
|-------------------|----------------------------------|
| `raw_teams`       | Team metadata per season         |
| `raw_matches`     | Match results and fixtures       |
| `raw_players`     | Player/squad data per season     |
| `raw_managers`    | Manager tenure history per club  |

## Staging Layer

All staging models are **incremental**, deduplicated on load, and keyed with an `md5`-hashed surrogate key:

- **`stg_matches`** — cleaned match data, keyed on `match_season_key`
- **`stg_teams`** — cleaned team data, keyed on `team_season_key`
- **`stg_team_squad`** — cleaned player/squad data, keyed on `player_season_team_key`
- **`stg_manager`** — cleaned manager tenure data, keyed on `club_key`; parses caretaker vs. incumbent managers and tenure date ranges

## Marts Layer

### Dimensions
- **`dim_teams`** — one row per team (latest season attributes)
- **`dim_season`** — season start/end date lookup
- **`dim_manager`** — distinct manager/nationality list

### Facts
| Model | Purpose |
|---|---|
| `fact_matches` | One row per match, enriched with home/away managers and team keys |
| `fact_standings` | End-of-season/point-in-time league table (wins, draws, losses, goal difference, points) |
| `fact_result_gameweek` | Match results unpivoted to one row per team per gameweek (home/away split) |
| `fact_home_away_performance` | Team performance broken out by Overall / Home / Away |
| `fact_points_category` | Points needed for Champions League, Top 4, relegation, etc. per season |
| `fact_season_manager` | Manager-to-season/team mapping |
| `fact_manager_days` | Days managed per manager per club |
| `fact_manager_total_match` | Aggregated match totals and win counts per manager |
| `fact_manager_win_streak` | Longest win streaks per manager |
| `fact_manager_unbeaten_streak` | Longest unbeaten streaks per manager |
| `fact_manager_opponent_position` | Manager performance vs. top-half/bottom-half opponents |
| `fact_stats_manager` | Aggregated manager statistics (clean sheets, goals, etc.) |
| `fact_team_squad` | Player roster per team/season, with computed age fields |

## Data Quality Tests

Defined in `models/schema.yml`, applied to staging primary keys:

- `unique` + `not_null` on `stg_matches.match_season_key`
- `unique` + `not_null` on `stg_teams.team_season_key`
- `unique` + `not_null` on `stg_team_squad.player_season_team_key`

## Getting Started

```bash
# Install deps and check connection
dbt debug

# Run all models
dbt run

# Run tests
dbt test

# Generate and view docs
dbt docs generate
dbt docs serve
```

### Docker

```bash
docker-compose up -d --build etl
```

## Configuration Notes

- Custom schema macro (`macros/generate_schema_name.sql`) disables dbt's default `<target_schema>_<custom_schema>` naming, so models land directly in the `staging` / `marts` schemas as configured in `dbt_project.yml`.
- Staging models are incremental and rely on a `loaded_at` watermark column to pick up new records only.

## Resources

- [dbt documentation](https://docs.getdbt.com/docs/introduction)
- [dbt Community Slack](https://community.getdbt.com/)
