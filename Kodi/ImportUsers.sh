#!/usr/bin/env bash
# Create user accounts from employees.csv
# Usage:  sudo ./add_users.sh employees.csv

set -euo pipefail

CSV_FILE="${1:-employees.csv}"
IFS=','                       # split on commas

# 1.  Create a primary group for every distinct department ------------
cut -d',' -f6 "$CSV_FILE" | tail -n +2 | sort -u | while read -r dept; do
    # Canonicalise: ASCII‑ify, lowercase, remove spaces
    group=$(echo "$dept" | iconv -f utf8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | tr -d ' ')
    if ! getent group "$group" >/dev/null; then
        echo "Creating group $group"
        groupadd "$group"
    fi
done

# 2.  Loop over employees and create their accounts -------------------
tail -n +2 "$CSV_FILE" | while read -r name firstname lastname username email dept empid; do
    group=$(echo "$dept" | iconv -f utf8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | tr -d ' ')
    # Random 12‑character temporary password
    password="$(openssl rand -base64 12)"
    echo "Adding $username ($name) to group $group"

    # Create the user with matching UID, home dir, comment, primary group
    useradd -m -u "$empid" -g "$group" -c "$name" "$username"

    # Set the password and force change at first log‑in
    echo "${username}:${password}" | chpasswd
    passwd -e "$username"

    # Optionally mail the password to the employee
    # printf '%s\n' "Your temporary password is $password" | mail -s "DDP account" "$email"
done

echo "✅  All users created."
