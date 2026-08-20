from datetime import datetime, timedelta
import os
from airflow import DAG
from airflow.operators.bash import BashOperator

# Default arguments applied to all tasks in this DAG
default_args = {
    'owner': 'reyhansyah',
    'depends_on_past': False,
    'start_date': datetime(2026, 1, 1),
    'email_on_failure': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'premier_league_isolated_pipeline',
    default_args=default_args,
    description='Orchestrates Premier League modular ingestion and dbt marts creation using BashOperator',
    schedule_interval='0 0 * * *', # Runs every day at 06:00 UTC
    catchup=False,
    max_active_runs=1
) as dag:

    # Task 1: Ingest Manager data from Wikipedia
    scrape_wikipedia = BashOperator(
        task_id='ingest_wikipedia_managers',
        bash_command='cd /opt/airflow/etl && python main.py scrape_wiki'
    )

    # Task 2: Ingest Match, Team, and Squad data from the REST API
    fetch_pl_api = BashOperator(
        task_id='ingest_api_football_data',
        bash_command='cd /opt/airflow/etl && python main.py fetch_api'
    )

    # Task 3: Build dbt Models (Runs staging, snapshots, tests, and marts)
    # Note: Ensure your dbt folder is mounted at /opt/airflow/dbt if you want to use it this way
    run_dbt = BashOperator(
        task_id='execute_dbt_marts',
        bash_command='cd /opt/airflow/dbt && dbt run'
    )

    # --- Task Dependencies ---
    # Both ingestion tasks execute in parallel. 
    # run_dbt will wait until BOTH are completed successfully.
    [scrape_wikipedia, fetch_pl_api] >> run_dbt