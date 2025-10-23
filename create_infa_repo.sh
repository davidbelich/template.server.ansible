#!/usr/bin/env bash
#
# create‑infra‑repo.sh
# -------------------------------------------------
# Creates the sample Ansible‑based infrastructure repository
# with the folder hierarchy and empty placeholder files
# shown in the design document.
#
# Usage: ./create‑infra‑repo.sh [target‑directory]
#   If no target directory is given, the script creates a folder
#   called "my-infra" in the current working directory.
# -------------------------------------------------

set -euo pipefail

# -------------------------------------------------------------------------
# Helper: print a nice heading
# -------------------------------------------------------------------------
h() {
    printf "\n\033[1;34m=== %s ===\033[0m\n\n" "$1"
}

# -------------------------------------------------------------------------
# Determine destination directory
# -------------------------------------------------------------------------
DEST="${1:-my-infra}"
echo "Creating repository layout in: $DEST"

# -------------------------------------------------------------------------
# Create directories (mkdir -p is idempotent)
# -------------------------------------------------------------------------
h "Creating directories"
mkdir -p "$DEST"/{docs,ansible/{group_vars,host_vars,inventories/dev,inventories/prod,apps/app-alpha/{roles/common/{tasks,defaults},vars,templates},apps/app-beta/{roles/db/{tasks,defaults},vars,templates},apps/app-gamma,library},secrets,.github/workflows}

# -------------------------------------------------------------------------
# Populate placeholder files
# -------------------------------------------------------------------------
h "Adding placeholder files"

# .gitignore
cat >"$DEST/.gitignore" <<'EOF'
# Ignore private host vars and real inventories
host_vars/*
inventories/prod/hosts.yml
secrets/*
*.retry
EOF

# README.md
cat >"$DEST/README.md" <<'EOF'
# My Infra Repository

This repository holds the public‑visible Ansible automation for our
applications.  Sensitive data (real inventories, vault passwords, etc.)
are kept outside of version control – see the `secrets/` directory (which
is listed in `.gitignore`).

## Layout overview'my‑infra/ ├─ .github/ │ └─ workflows/ │ └─ deploy.yml # CI example (add your own) ├─ docs/ │ ├─ architecture.md │ └─ onboarding.md ├─ ansible/ │ ├─ site.yml │ ├─ requirements.yml │ ├─ group_vars/all.yml │ ├─ host_vars/ # ← keep private, not committed │ ├─ inventories/ │ │ ├─ dev/hosts.yml # placeholders only │ │ └─ prod/hosts.yml # placeholders only │ ├─ apps/ │ │ ├─ app‑alpha/ │ │ │ ├─ playbook.yml │ │ │ ├─ roles/common/tasks/main.yml │ │ │ ├─ roles/common/defaults/main.yml │ │ │ ├─ vars/main.yml │ │ │ ├─ vars/vault.yml # encrypted with ansible‑vault │ │ │ └─ templates/nginx.conf.j2 │ │ └─ app‑beta/ … │ └─ library/ ├─ secrets/ # ← not tracked, holds real inventories & vault password └─ .gitignore


## Adding a new app
Copy the `apps/app‑alpha` skeleton, rename it, and adjust the playbook
and role names as needed.

EOF

# Minimal placeholder files for each component
touch "$DEST/docs/architecture.md"
touch "$DEST/docs/onboarding.md"

# ansible top‑level files
touch "$DEST/ansible/site.yml"
touch "$DEST/ansible/requirements.yml"
touch "$DEST/ansible/group_vars/all.yml"

# Placeholder host_vars README (explains why it's ignored)
cat >"$DEST/ansible/host_vars/README.md" <<'EOF'
# Host‑specific variables

This directory is intentionally left empty in the public repository.
Real host‑specific variables (including secrets) should be stored in a
private location and referenced via an encrypted vault or external secret
manager. The directory is listed in `.gitignore` so it never gets
committed.
EOF

# Inventories – dev and prod placeholders
cat >"$DEST/ansible/inventories/dev/hosts.yml" <<'EOF'
# Development inventory – placeholder hostnames
[web]
web01.dev.local

[db]
db01.dev.local
EOF

cat >"$DEST/ansible/inventories/prod/hosts.yml" <<'EOF'
# Production inventory – placeholder hostnames only.
# Real production inventory lives in the untracked `secrets/` folder.
[web]
web01.prod.local

[db]
db01.prod.local
EOF

# -------------------------------------------------------------------------
# Application skeletons (alpha, beta, gamma)
# -------------------------------------------------------------------------
for APP in alpha beta gamma; do
    BASE="$DEST/ansible/apps/app-$APP"

    # Common files for every app
    touch "$BASE/playbook.yml"
    touch "$BASE/vars/main.yml"
    touch "$BASE/vars/vault.yml"   # will be encrypted later with ansible‑vault
    touch "$BASE/templates/example.j2"

    # Role skeleton – each app gets its own role namespace
    ROLE_DIR="$BASE/roles"
    mkdir -p "$ROLE_DIR"

    # Example role(s) – you can add more as needed
    if [[ "$APP" == "alpha" ]]; then
        ROLE="common"
    elif [[ "$APP" == "beta" ]]; then
        ROLE="db"
    else
        ROLE="web"
    fi

    mkdir -p "$ROLE_DIR/$ROLE/tasks"
    mkdir -p "$ROLE_DIR/$ROLE/defaults"

    touch "$ROLE_DIR/$ROLE/tasks/main.yml"
    touch "$ROLE_DIR/$ROLE/defaults/main.yml"
done

# -------------------------------------------------------------------------
# CI workflow placeholder
# -------------------------------------------------------------------------
cat >"$DEST/.github/workflows/deploy.yml" <<'EOF'
name: Deploy Infrastructure

on:
  push:
    branches: [main]

jobs:
  ansible-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      # Example: retrieve vault password from repository secret
      - name: Set up Ansible Vault password
        env:
          VAULT_PASS: ${{ secrets.ANSIBLE_VAULT_PASSWORD }}
        run: |
          echo "$VAULT_PASS" > vault_pass.txt
          chmod 600 vault_pass.txt

      - name: Install Ansible
        run: sudo apt-get update && sudo apt-get install -y ansible

      - name: Run playbook
        env:
          ANSIBLE_VAULT_PASSWORD_FILE: $(pwd)/vault_pass.txt
        run: |
          ansible-playbook -i ansible/inventories/dev/hosts.yml ansible/site.yml
EOF

# -------------------------------------------------------------------------
# Library folder (custom plugins) – just a placeholder file
# -------------------------------------------------------------------------
touch "$DEST/ansible/library/README.md"

# -------------------------------------------------------------------------
# Final message
# -------------------------------------------------------------------------
h "Done!"
printf "Repository skeleton created at: %s\n" "$(realpath "$DEST")"
printf "\nNext steps:\n"
printf "  1️⃣  Initialise a git repo:   cd %s && git init\n" "$DEST"
printf "  2️⃣  Add remote, commit, push…\n"
printf "  3️⃣  Populate the placeholder files with real content.\n"
printf "  4️⃣  Encrypt any secret variable files with:\n"
printf "       ansible-vault encrypt %s/ansible/apps/<app>/vars/vault.yml\n" "$DEST"
printf "  5️⃣  Store the vault password in your CI secret store (e.g., GitHub Actions).\n"
printf "\nHappy automating!\n"