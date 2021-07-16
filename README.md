![Datasentinel](images/datasentinel-logo.jpg)

#### [Datasentinel](https://www.datasentinel.io) is a unique and innovative performance tool for Postgresql

#### See our [Live Demo](https://demo.datasentinel.io)


<br>

## The toolkit helps you easily use the API
<hr>

This toolkit is composed of simple ansible playbooks and bash scripts. It is installed by default in the home directory  
(/home/datasentinel) of the user **datasentinel** in the centralized platform. 

<br>

## Ansible examples
<hr>

For simplicity, all variables are defined in the header of each playbook

Ansible is a very popular tool and is installed by default on the Datasentinel platform

Connect as datasentinel on the platform server:
```
ansible --version
```
<br>

## Update agents
<hr>

The **update_agents.yml** playbook is an example on how to update deployed agents with a new version 

You need to download new versions and put them in the directory /datasentinel/download (**local_dir** variable)

Example
```
ansible-playbook update_agents.yml -i hosts
```
<br>

## To use API, you need to authenticate with a user/password to get a valid access token

<br>

## Documentation

The Datasentinel documentation is available at [www.datasentinel.io/documentation/](https://www.datasentinel.io/documentation/)

<br>

## Activity API
<hr>

The API documentation is available at [Activity API documentation](https://doc.datasentinel.io/features/APIs.html)

The **activity_api** playbook is an example on how to export activity metrics from Datasentinel 

Example
```
ansible-playbook activity_api.yml  -e "datasentinel_host=myHost datasentinel_password=myPassword" --tags indexes
```

<br>

## Reporting API
<hr>

This API allows you to generate a complete workload report in PDF format

The **generate_pdf_report** playbook is an example on how to generate a PDF file

Example
```
ansible-playbook generate_pdf_report.yml  -e "datasentinel_host=myHost datasentinel_password=myPassword" --tags indexes
```

<br>

## Connection manager API 

<hr>

It uses the **Agentless** feature of Datasentinel

Only a user with **data admin** profile and **admin** privilege is authorized to use it

The **connection_manager** playbook creates, updates, enables, disables and finally deletes a connection

Example
```
ansible-playbook connection_manager.yml -e "datasentinel_host=myHost datasentinel_password=MyDatasentinelPassword pg_password=myPgPassword"
```

The **bulk_load_connections** playbook is an example on how to import multiple connections 

Example
```
ansible-playbook bulk_load_connections.yml -e "datasentinel_host=myHost datasentinel_password=MyDatasentinelPassword pg_password=myPgPassword"
```
<br>

## User and Role API 
<hr>

Only a user with **data admin** profile and **admin** privilege is authorized to use it

The **user_api** playbook creates, updates and deletes roles and users.

Example
```
ansible-playbook user_api.yml -e "datasentinel_host=myHost datasentinel_password=MyDatasentinelPassword 
```

<br>
<br>

# Shell scripts

## Connection manager API 
<hr>

Example
```
./connection_manager_api.sh -d datasentinel_server -p password -u user
```
<br>

## Users and Roles API 
<hr>

Example
```
./user_api.sh -d datasentinel_server -p password -u user
```
<br>

## Workload export as PDF 
<hr>

Example
```
./generate_pdf_report.sh -d datasentinel_server -p password -u user
```