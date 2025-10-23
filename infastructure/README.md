# My Infra Repository

This repository holds the public‑visible Ansible automation for our
applications.  Sensitive data (real inventories, vault passwords, etc.)
are kept outside of version control – see the `secrets/` directory (which
is listed in `.gitignore`).

## Layout overview'my‑infra/ ├─ .github/ │ └─ workflows/ │ └─ deploy.yml # CI example (add your own) ├─ docs/ │ ├─ architecture.md │ └─ onboarding.md ├─ ansible/ │ ├─ site.yml │ ├─ requirements.yml │ ├─ group_vars/all.yml │ ├─ host_vars/ # ← keep private, not committed │ ├─ inventories/ │ │ ├─ dev/hosts.yml # placeholders only │ │ └─ prod/hosts.yml # placeholders only │ ├─ apps/ │ │ ├─ app‑alpha/ │ │ │ ├─ playbook.yml │ │ │ ├─ roles/common/tasks/main.yml │ │ │ ├─ roles/common/defaults/main.yml │ │ │ ├─ vars/main.yml │ │ │ ├─ vars/vault.yml # encrypted with ansible‑vault │ │ │ └─ templates/nginx.conf.j2 │ │ └─ app‑beta/ … │ └─ library/ ├─ secrets/ # ← not tracked, holds real inventories & vault password └─ .gitignore


## Adding a new app
Copy the `apps/app‑alpha` skeleton, rename it, and adjust the playbook
and role names as needed.

