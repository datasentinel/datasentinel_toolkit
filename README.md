![Datasentinel](images/datasentinel-logo.jpg)

#### [Datasentinel](https://www.datasentinel.io) is a unique and innovative performance tool for Postgresql

#### [Cloud application](https://app.datasentinel.io) (Live demo available)

## The toolkit helps you easily use the API

This toolkit is composed of simple ansible playbooks and bash scripts. It is installed by default in the home directory  
(/home/datasentinel) of the user **datasentinel** in the centralized platform. 


## Ansible examples

For simplicity, all variables are defined in the header of each playbook

Ansible is a very popular tool and is installed by default on the Datasentinel platform

Connect as datasentinel on the platform server:
```
ansible --version
```

To use API, you need to authenticate with a user/password to get a valid access token


## Documentation

The Datasentinel documentation is available at [doc.datasentinel.io/index.html](https://doc.datasentinel.io/index.html)

## Activity API

The API documentation is available at [Activity API documentation](https://doc.datasentinel.io/features/APIs.html)

The **activity_api** playbook is an example on how to export activity metrics from Datasentinel 

Example
```
ansible-playbook activity_api.yml  -e "datasentinel_host=myHost datasentinel_password=myPassword" --tags indexes
```

## Connection manager API 
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
