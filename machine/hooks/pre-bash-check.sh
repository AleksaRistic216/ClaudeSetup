#!/bin/bash
# PreToolUse hook for Bash — blocks dangerous process-kill patterns

input=$(cat)
command=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('command',''))" 2>/dev/null)

# Block lsof -ti:PORT | xargs kill — kills ALL processes on that port, including browsers
if echo "$command" | grep -qP 'lsof\s+[^\n]*-[a-zA-Z]*i[:\s][0-9]+[^\n]*\|[^\n]*kill'; then
    echo "BLOCKED: 'lsof -ti:PORT | xargs kill' targets all processes on that port and can kill the browser."
    echo "Use 'pkill -f <exact-process-name>' instead to target only the app process."
    exit 2
fi

exit 0
