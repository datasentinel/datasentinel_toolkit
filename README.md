![Datasentinel](images/datasentinel-logo.jpg)

#### [Datasentinel](https://www.datasentinel.io) is a performance monitoring platform for PostgreSQL

This toolkit gathers ready-to-use examples for operating Datasentinel as code: Ansible playbooks and shell scripts that call the platform API, a playbook to upgrade deployed agents, the optional `datasentinel_analytics` function for agentless connections, an alerting hook example, and container deployment files.

It is installed by default in the home directory of the **datasentinel** user (`/home/datasentinel`) on the platform server, where Ansible is already available.

Documentation: [docs.datasentinel.io](https://docs.datasentinel.io) · API reference: [Platform API](https://docs.datasentinel.io/implementation/platform-usage/api-reference)

## Contents

| Path | What it is |
| --- | --- |
| `activity_api.yml` | Export activity metrics (instance, sessions, queries, tables, indexes, ...) to JSON files |
| `generate_pdf_report.yml` | Generate a workload report in PDF format |
| `connection_manager_api.yml` / `connection_manager_api.sh` | Create, update, enable, disable and delete an agentless PostgreSQL connection |
| `bulk_load_connections.yml` / `bulk_load_connections.sh` | Register many agentless connections in one run |
| `user_api.yml` / `user_api.sh` | Create, update and delete roles and users, assign a role to a user |
| `ldap_user_api.yml` / `ldap_user_api.sh` | Add a user authenticated by LDAP, with the matching Grafana user |
| `api_reports.sh` | Generate the top queries and workload PDF reports and send them by email |
| `update_agents.yml` | Upgrade the Datasentinel agents deployed on your PostgreSQL hosts |
| `datasentinel_analytics/` | The optional `datasentinel_analytics` function and its install / remove scripts |
| `alerting_script_example.sh` | Example of a script run by the alerting engine at each notification |
| `docker/` | Docker Compose and Kubernetes files for the platform and the agent |
| `roles/create_user_token` | Ansible role shared by the playbooks to obtain an API access token |
| `metrics/` | Sample output of `activity_api.yml` and `generate_pdf_report.yml` |
| `hosts` | Inventory example for `update_agents.yml` |

## Before you start

Every API call needs an access token, obtained with a Datasentinel user and password. See [Access Token](https://docs.datasentinel.io/implementation/platform-usage/api-reference/access-token).

- The playbooks get the token through the `roles/create_user_token` role.
- The shell scripts get it themselves and need `curl` and `python3`.

The connection, user and role APIs require a user with the **data admin** profile and the **admin** privilege.

All variables are defined at the top of each playbook. Override them on the command line with `-e`:

```
ansible-playbook <playbook>.yml -e "datasentinel_host=myHost datasentinel_user=myUser datasentinel_password=myPassword"
```

The shell scripts take the same three settings as options:

```
./<script>.sh -d datasentinel_host -u user -p password
```

Each script and playbook is an example: read it and adapt the objects it creates (connection names, tags, roles, users) before running it.

## Platform API: Ansible playbooks

### Activity metrics

`activity_api.yml` exports the metrics of one instance over a time window to JSON files in `metrics/`. Each metric family has its own tag, so you can export only what you need.

```
ansible-playbook activity_api.yml -e "datasentinel_host=myHost datasentinel_password=myPassword" --tags indexes
```

Tags: `server`, `background`, `data-size`, `sessions`, `queries`, `tables`, `indexes`. Without `--tags`, every family is exported.

### PDF report

`generate_pdf_report.yml` generates the workload report of one instance over a time window. See [Reporting API](https://docs.datasentinel.io/implementation/platform-usage/api-reference/reporting).

```
ansible-playbook generate_pdf_report.yml -e "datasentinel_host=myHost datasentinel_password=myPassword pg_connection=myInstance"
```

### Connections (agentless)

`connection_manager_api.yml` walks through the life cycle of one agentless connection: create, update, enable, disable, delete. See [Connection API](https://docs.datasentinel.io/implementation/platform-usage/api-reference/connection) and [Agentless Monitoring](https://docs.datasentinel.io/features/other-features/agentless-monitoring).

```
ansible-playbook connection_manager_api.yml -e "datasentinel_host=myHost datasentinel_password=myPassword pg_password=myPgPassword"
```

`bulk_load_connections.yml` registers the connections listed in its `pg_connections` variable, each with its own tags.

```
ansible-playbook bulk_load_connections.yml -e "datasentinel_host=myHost datasentinel_password=myPassword pg_password=myPgPassword"
```

### Users and roles

`user_api.yml` creates a role, creates users with and without properties, assigns the role, then cleans up. See [Role API](https://docs.datasentinel.io/implementation/platform-usage/api-reference/role) and [User API](https://docs.datasentinel.io/implementation/platform-usage/api-reference/user).

```
ansible-playbook user_api.yml -e "datasentinel_host=myHost datasentinel_password=myPassword"
```

`ldap_user_api.yml` adds a user authenticated by LDAP when Grafana sign-up is disabled: it creates the Grafana user with the Grafana admin account, then the Datasentinel user.

```
ansible-playbook ldap_user_api.yml -e "datasentinel_host=myHost datasentinel_password=myPassword grafana_admin_password=myGrafanaPassword"
```

## Platform API: shell scripts

The scripts run the same scenarios with `curl`, for environments without Ansible.

| Script | Scenario |
| --- | --- |
| `connection_manager_api.sh` | Create a connection, show its status, update, disable, enable, delete |
| `bulk_load_connections.sh` | Create several connections |
| `user_api.sh` | Create a role, create a user, assign the role, delete both |
| `ldap_user_api.sh` | Same as above for an LDAP-authenticated user |
| `api_reports.sh` | Generate the top queries and workload PDF reports for the current day and send them by email |

```
./connection_manager_api.sh -d datasentinel_host -u user -p password
./user_api.sh -d datasentinel_host -u user -p password
./api_reports.sh -d datasentinel_host -u user -p password
```

`api_reports.sh` asks the platform to generate each report and email it (`report_type: email`), so the platform's SMTP settings must be configured. Edit the instance name, time window and report filters at the top of the script.

## Upgrade the agents

`update_agents.yml` upgrades the agents deployed on your PostgreSQL hosts to a new version, keeping each agent's configuration. It picks the RedHat or Debian package from the host's distribution.

1. Download the new agent packages from [Installation › Agent](https://docs.datasentinel.io/getting-started/installation/agent) into `/datasentinel/download` on the platform server (the `local_dir` variable).
2. List the PostgreSQL hosts in the `hosts` inventory.
3. Run the playbook:

```
ansible-playbook update_agents.yml -i hosts
```

See [Upgrade › Agent](https://docs.datasentinel.io/implementation/upgrade/agent).

## Internal function (datasentinel_analytics)

The optional **datasentinel_analytics** function gives Datasentinel read-only access to planner statistics and execution plans, without any SELECT privilege on application tables. It enables table and index bloat estimates, column and extended statistics, and live execution plans. See [Internal Function](https://docs.datasentinel.io/getting-started/postgresql-clusters/internal-function).

The agent package ships the function. The `datasentinel_analytics/` directory holds the same three files for **agentless** connections, where no agent is downloaded:

| File | Purpose |
| --- | --- |
| `datasentinel_analytics.sql` | The function definition and the `REVOKE ... FROM PUBLIC` |
| `deploy_datasentinel_function.sh` | Installs the function in every application database and grants EXECUTE to `datasentinel` |
| `remove_datasentinel_function.sh` | Removes the function from every application database |

The function must be installed by a **superuser** (or the master user on a cloud-managed instance) in **each application database**. Run the scripts from the directory that holds the SQL file. The optional argument is the PostgreSQL port (default 5432).

On the PostgreSQL host:

```
cd datasentinel_analytics
./deploy_datasentinel_function.sh 5432
```

From a remote machine with `psql` installed:

```
cd datasentinel_analytics
PGHOST=myPgHost PGUSER=postgres PGPASSWORD=myPgPassword ./deploy_datasentinel_function.sh 5432
```

- If the monitoring user is not named **datasentinel**, edit `TARGET_USER` in the script first.
- Run the deploy script again after creating a new database, or after an upgrade that changes the SQL file. It uses `CREATE OR REPLACE`, so running it again is safe.
- `./remove_datasentinel_function.sh 5432` removes the function from every application database.

## Alerting script

`alerting_script_example.sh` is a minimal script the alerting engine can run at each notification. It receives six arguments (event time, notification type, instance, check name, state, message) and appends them to `~/datasentinel_notifications.log`. Use it as the starting point for your own integration. See [Alerting](https://docs.datasentinel.io/features/key-features/alerting).

## Docker and Kubernetes

The `docker/` directory holds a Docker Compose file and Kubernetes manifests for the platform, and a Dockerfile with examples for the agent. See [docker/README.md](docker/README.md).

## License

See [LICENSE](LICENSE).
