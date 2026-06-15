import sys
task = sys.argv[1] if len(sys.argv) > 1 else "all"


if task == "scrape_wiki" or task == "all":
    print("scrape_wiki task executed successfully!")

# ----------------------------------------------------
# TASK 2: Premier League REST API Ingestion
# ----------------------------------------------------
if task == "fetch_api" or task == "all":
    print("fetch_api task executed successfully!")

if task != "scrape_wiki" and task != "fetch_api" and task != "all":
    print(f"[ERROR] Unknown task argument passed: '{task}'")
    print("Valid tasks are: 'scrape_wiki', 'fetch_api', or 'all'")
    sys.exit(1)