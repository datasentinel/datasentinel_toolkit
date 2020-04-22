# The Datasentinel toolkit helps you easily use the API

- ### Some ansible playbooks are present as examples to help you use API
- ### ansible is installed and configured on the Datasentinel platform server.
Connect as datasentinel user.

```
ansible --version
```

- ### To use API, you need to authenticate with a user:password.
- ### User must be created in the UI with a **data admin** or **developer** profile

## 1. Activity API

## 2. Connection manager 
Only data admin profile is authorized to use it

The **connection_manager** playbook creates, updates, enables, disables and finally deletes a connection
For more simplicity, all connection fields are defined in the header of each playbook

```
ansible-playbook connection_manager.yml -e "datasentinel_url=myUrl datasentinel_password=MyDatasentinelPassword pg_password=myPgPassword"```

### ***To be used only with the agentless version***
Only data admin profile is authorized to use it


```

```
## 3 Pool manager

### ***To be used only with the agentless version***




