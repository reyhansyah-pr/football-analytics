import os
import sys
from dotenv import load_dotenv

load_dotenv()

from premier_league import PremierLeagueScraper
from postgre_loader import PostgresLoader
from scrape_wiki import WikiTableParser

if __name__ == "__main__":
    # Read task argument from Airflow BashOperator command line execution
    # e.g., 'python main.py scrape_wiki' -> sys.argv[1] becomes 'scrape_wiki'
    task = sys.argv[1] if len(sys.argv) > 1 else "all"

    # Initialize the Postgres Connection Engine (Used by all tasks)
    loader = PostgresLoader(
        user=os.getenv("POSTGRES_USER"),
        password=os.getenv("POSTGRES_PASSWORD"),
        host=os.getenv("POSTGRES_HOST"),
        # host="localhost",
        port=5432,
        database=os.getenv("POSTGRES_DB")
    )

    # ----------------------------------------------------
    # TASK 1: Wikipedia Manager Ingestion
    # ----------------------------------------------------
    if task == "scrape_wiki" or task == "all":
        print("\n" + "="*50)
        print("Executing Task: Ingesting Wikipedia Managers...")
        print("="*50)
        
        parser = WikiTableParser('https://en.wikipedia.org/wiki/List_of_Premier_League_managers')
        manager_df = parser.parse_managers_table()

        print("Scraping Completed. Sample Data:")
        print(manager_df.head(3))
        
        print("Starting Data Load: raw_managers into PostgreSQL...")
        loader.load_dataframe(manager_df, "raw_managers", schema="raw")
        print("Wikipedia Ingestion Task Completed Successfully!")

    # ----------------------------------------------------
    # TASK 2: Premier League REST API Ingestion
    # ----------------------------------------------------
    if task == "fetch_api" or task == "all":
        print("\n" + "="*50)
        print("Executing Task: Ingesting Premier League REST API Data...")
        print("="*50)
        
        scraper = PremierLeagueScraper(season_start=2025, season_end=2025)

        print("Fetching Teams...")
        teams_df = scraper.get_teams()
        
        print("Fetching Squads/Players...")
        players_df = scraper.get_all_squads()
        
        print("Fetching Match Results...")
        matches_df = scraper.get_matches(matchweeks=1) # Keeps testing fast with 1 matchweek

        print("Starting Data Load: API dataframes into PostgreSQL...")
        loader.load_dataframe(teams_df, "raw_teams", schema="raw")
        loader.load_dataframe(players_df, "raw_players", schema="raw")
        loader.load_dataframe(matches_df, "raw_matches", schema="raw")
        print("REST API Ingestion Task Completed Successfully!")

    if task != "scrape_wiki" and task != "fetch_api" and task != "all":
        print(f"[ERROR] Unknown task argument passed: '{task}'")
        print("Valid tasks are: 'scrape_wiki', 'fetch_api', or 'all'")
        sys.exit(1)