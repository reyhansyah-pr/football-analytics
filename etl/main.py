import os
from dotenv import load_dotenv

load_dotenv()

from premier_league import PremierLeagueScraper
from postgre_loader import PostgresLoader
from scrape_wiki import WikiTableParser


if __name__ == "__main__":
    print("Starting ETL Process...")
    print("="*50)
    print("Start Scraping List Manager Premier League from Wikipedia...")

    parser = WikiTableParser('https://en.wikipedia.org/wiki/List_of_Premier_League_managers')
    manager_df = parser.parse_managers_table()

    print("Scraping Completed. Sample Data:")
    print(manager_df.head(3))
    print("="*50)
    print("Fetching Premier League match data via REST API...")

    scraper = PremierLeagueScraper(season_start=2025, season_end=2025)

    teams_df = scraper.get_teams()
    players_df = scraper.get_all_squads()
    matches_df = scraper.get_matches(matchweeks=38)

    loader = PostgresLoader(
        user=os.getenv("POSTGRES_USER"),
        password=os.getenv("POSTGRES_PASSWORD"),
        host=os.getenv("POSTGRES_HOST"),
        # host='localhost',
        port=5432,
        database=os.getenv("POSTGRES_DB")
    )

    print("Starting Data Load into PostgreSQL...")

    loader.load_dataframe(teams_df, "raw_teams", schema="raw")
    loader.load_dataframe(players_df, "raw_players", schema="raw")
    loader.load_dataframe(matches_df, "raw_matches", schema="raw")
    loader.load_dataframe(manager_df, "raw_managers", schema="raw")

    print("Data Load Completed.")

    print("ETL Process Completed Successfully!")