# Setup Go to Pull Private Modules
There are two things that must be setup:
1. Setup ~/.gitconfig
2. Set GOPRIVATE

## Setup ~/.gitconfig
1. Generate a Personal Access Token (PAT) on [Github](https://github.azc.ext.hp.com)
2. Configure ~/.gitconfig, replace `ghp_abcdefghijklmnopqrstuvwxyz0123456789` with your PAT

```bash
$ git config --global user.name "Your Name"
$ git config --global user.email "your.email@hp.com"
$ git config --global --add url."https://ghp_abcdefghijklmnopqrstuvwxyz0123456789@github.azc.ext.hp.com".insteadOf "https://github.azc.ext.hp.com"
$ cat ~/.gitconfig 
[user]
	name = Your Name
	email = your.email@hp.com
[url "https://ghp_abcdefghijklmnopqrstuvwxyz0123456789@github.azc.ext.hp.com"]
	insteadOf = https://github.azc.ext.hp.com/
```

## Set GOPRIVATE
Run the following:

```bash
go env -w GOPRIVATE="github.azc.ext.hp.com/*"
```
