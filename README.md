![Datasentinel](images/datasentinel-logo.jpg)


# This toolkit helps you easily use the API

## Documentation

The Datasentinel documentation is available at [doc.datasentinel.io/index.html](https://doc.datasentinel.io/index.html).

- Some ansible playbooks are present as examples to help you
- ansible is installed and configured on the Datasentinel platform server.
Connect as datasentinel user.

```
ansible --version
```

- To use API, you need to authenticate with a user/password to get a valid access token

## 1. Activity API

## 2. Connection manager 
Only data admin profile is authorized to use it

The **connection_manager** playbook creates, updates, enables, disables and finally deletes a connection
For more simplicity, all connection fields are defined in the header of each playbook

```
ansible-playbook connection_manager.yml -e "datasentinel_password=myUserPassword"
```

### ***To be used only with the agentless version***
Only data admin profile is authorized to use it


```

```
## 3 Pool manager

### ***To be used only with the agentless version***




