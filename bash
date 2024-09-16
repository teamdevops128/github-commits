#!/bin/bash


ORG="y"
DAYS=30
START_DATE=$(date -d "-${DAYS} days" "+%Y-%m-%dT%H:%M:%SZ")
CSV_FILE="commit_data.csv"
REPO_FILE="repos.csv"


if [ ! -f "$REPO_FILE" ]; then
    echo "Error: $REPO_FILE does not exist."
    exit 1
fi

echo "Repository,Branch,Commits_Last_30_Days" > $CSV_FILE

get_commit_count() {
    local repo=$1
    local branch=$2
    local page=1
    local total_commits=0

    while true; do
        # GitHub API request for commits in the last 30 days on a specific branch
        response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/repos/${ORG}/${repo}/commits?sha=${branch}&since=$START_DATE&per_page=100&page=$page")

        
        commit_count=$(echo "$response" | jq length)

        if [ "$commit_count" -eq 0 ]; then
            break
        fi

    
        total_commits=$((total_commits + commit_count))
        page=$((page + 1))
    done

 
    echo "$repo,$branch,$total_commits" >> $CSV_FILE
}


get_branches() {
    local repo=$1


    branches=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/${ORG}/${repo}/branches?per_page=100")

    echo "$branches" | jq -r '.[].name'
}


while IFS=, read -r repo; do

    if [ "$repo" == "Repository" ]; then
        continue
    fi

    branches=$(get_branches "$repo")
    
    for branch in $branches; do
        echo "Processing $repo on branch $branch..."
        get_commit_count "$repo" "$branch"
    done
done < "$REPO_FILE"

echo "Commit data saved to $CSV_FILE"
