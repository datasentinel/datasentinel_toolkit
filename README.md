![Datasentinel](images/datasentinel-logo.jpg)


# This toolkit helps you easily use the API

This toolkit is composed of simple ansible playbooks

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

***Coming soon***

## Connection manager API 
It uses the Agentless feature of Datasentinel

Only a user with **data admin** profile is authorized to use it

The **connection_manager** playbook creates, updates, enables, disables and finally deletes a connection

```
ansible-playbook connection_manager.yml -e "datasentinel_url=myUrl datasentinel_password=MyDatasentinelPassword pg_password=myPgPassword"
```

## Pool manager

***Coming soon***
