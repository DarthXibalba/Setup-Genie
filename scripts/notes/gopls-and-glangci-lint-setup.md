### Need to install curl
```
sudo apt-get install curl -y
```

### golangci-lint
Install the `golangci-lint` tool to be able to lint your code before you check it in. [Installation instructions](https://golangci-lint.run/usage/install/) are summarized below:
```
# For local installation, binary will be $(go env GOPATH)/bin/golangci-lint
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin

# OR for system-wide installation (only if go was installed in /usr/local/go/bin)
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sudo sh -s -- -b /usr/local/go/bin
```

Then to run lint (run at the top level of k9s, same level as README):
```
$ make lint
golangci-lint run --new-from-rev=main --issues-exit-code 1 // Successful
```

### Gopls setup
Using the above settings, gopls(and any dependant plugins like vscode go) won't autocomplete or syntax check integration tests. To fix this, gopls needs the `build.buildflags` to include the flag `"-tags=integration"`

VSCode example(Settings > Workspace > gopls > settings.json):
```json
{
    "gopls": {
        "build.buildFlags": ["-tags=integration e2e"]
    }
}
```