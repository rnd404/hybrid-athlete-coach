#!/usr/bin/env bash
# Pre-push privacy check. Run from the repository root before every push.
# - Fails if personal data folders are present.
# - Fails on generic sensitive patterns (emails, phone numbers, dd/mm/yyyy dates).
# - Also checks every regex listed in ./.sensitive-patterns (LOCAL file, gitignored:
#   put names, clinic names, birth date, etc. there — never in the repo).
set -u
fail=0

for d in strength massimali pain-log coach/personal; do
  if [ -e "$d" ]; then echo "FAIL: personal folder present: $d"; fail=1; fi
done

scan() { # $1 = label, $2 = regex
  hits=$(grep -rInE --exclude-dir=.git --exclude=.sensitive-patterns --exclude=pre_push_check.sh -e "$2" . 2>/dev/null)
  if [ -n "$hits" ]; then echo "FAIL [$1]:"; echo "$hits"; fail=1; fi
}

scan email   '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
scan phone   '(\+39|\b3[0-9]{2})[ .-]?[0-9]{3}[ .-]?[0-9]{4}\b'
scan date    '\b[0-9]{1,2}/[0-9]{1,2}/(19|20)[0-9]{2}\b'

if [ -f .sensitive-patterns ]; then
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    case "$p" in \#*) continue;; esac
    scan "local:$p" "$p"
  done < .sensitive-patterns
else
  echo "WARN: no .sensitive-patterns file found (local-only list of names/dates to block)."
fi

command -v gitleaks >/dev/null 2>&1 && { gitleaks detect --no-banner || fail=1; } \
  || echo "INFO: gitleaks not installed (recommended: https://github.com/gitleaks/gitleaks)"

[ $fail -eq 0 ] && echo "OK: no issues found." || { echo "Push blocked: fix the items above."; exit 1; }
