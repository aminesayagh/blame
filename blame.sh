#!/bin/bash

# Check if the script is run inside a Git repository
if [ ! -d .git ]; then
  echo "This is not a Git repository. Please run this script inside a Git repository."
  exit 1
fi

echo "Gathering contributors and counting lines of code..."

# Get the list of all contributors (sorted uniquely)
contributors=$(git log --format='%aN' | sort -u)

# Use associative arrays to store data
declare -A contributor_lines
declare -A contributor_first_commit
declare -A contributor_last_week

# Get the date of one week ago
one_week_ago=$(date --date="7 days ago" +"%Y-%m-%d")

# Loop through each contributor
for author in $contributors; do
  # Count total lines of code
  total_lines=$(git log --author="$author" --pretty=tformat: --numstat | awk '{ added+=$1; deleted+=$2 } END { print added - deleted }')

  # Get first commit date of the author
  first_commit=$(git log --author="$author" --reverse --format="%as" | head -n 1)

  # Count lines of code committed in the last week
  last_week_lines=$(git log --since="$one_week_ago" --author="$author" --pretty=tformat: --numstat | awk '{ added+=$1; deleted+=$2 } END { print added - deleted }')

  # Store values in associative arrays
  contributor_lines["$author"]=$total_lines
  contributor_first_commit["$author"]=$first_commit
  contributor_last_week["$author"]=${last_week_lines:-0}  # Default to 0 if no recent commits
done

# Print header
echo -e "\nContributor\t\tTotal Lines\tLast Week\tFirst Commit Date"
echo "---------------------------------------------------------------------"

# Print contributors sorted by total lines of code in descending order
for author in "${!contributor_lines[@]}"; do
  printf "%-20s %10d %10d %15s\n" "$author" "${contributor_lines[$author]}" "${contributor_last_week[$author]}" "${contributor_first_commit[$author]}"
done | sort -k2 -nr | column -t
