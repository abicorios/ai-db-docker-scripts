#!/bin/bash

# Script to execute ONLY SELECT queries safely using Docker environment variables
# This script blocks all modification queries (UPDATE, DELETE, INSERT, etc.)

# Check if query is provided
if [ -z "$1" ]; then
    echo "Error: No SQL query provided"
    echo "Usage: $0 'SQL_QUERY'"
    exit 1
fi

# Convert query to uppercase for checking (preserving original for execution)
QUERY_UPPER=$(echo "$1" | tr '[:lower:]' '[:upper:]')

# List of allowed keywords (read-only operations)
ALLOWED_PATTERNS=(
    "^SELECT "
    "^SHOW "
    "^DESCRIBE "
    "^DESC "
    "^EXPLAIN "
    "^WITH "
)

# Check if query starts with allowed pattern
IS_ALLOWED=0
for PATTERN in "${ALLOWED_PATTERNS[@]}"; do
    if [[ "$QUERY_UPPER" =~ $PATTERN ]]; then
        IS_ALLOWED=1
        break
    fi
done

# If not allowed, exit with error
if [ "$IS_ALLOWED" -eq 0 ]; then
    echo "Error: Only SELECT, SHOW, DESCRIBE, and EXPLAIN queries are allowed"
    echo "Query blocked: $1"
    exit 1
fi

# List of dangerous keywords that should never appear
DANGEROUS_KEYWORDS=(
    "UPDATE "
    "DELETE "
    "INSERT "
    "DROP "
    "TRUNCATE "
    "ALTER "
    "CREATE "
    "REPLACE "
    "GRANT "
    "REVOKE "
    "LOCK "
    "UNLOCK "
    "KILL "
    "FLUSH "
    "OPTIMIZE "
    "REPAIR "
    "RENAME "
)

# Check for dangerous keywords anywhere in the query
for KEYWORD in "${DANGEROUS_KEYWORDS[@]}"; do
    if [[ "$QUERY_UPPER" == *"$KEYWORD"* ]]; then
        echo "Error: Query contains dangerous keyword: $KEYWORD"
        echo "Query blocked: $1"
        exit 1
    fi
done

# Execute the query
docker compose exec db bash -c 'echo -e "[client]\nuser=$MYSQL_USER\npassword=$MYSQL_PASSWORD" > /tmp/my.cnf && mysql --defaults-extra-file=/tmp/my.cnf $MYSQL_DATABASE --default-character-set=utf8 -e "'"$1"'" && rm /tmp/my.cnf'