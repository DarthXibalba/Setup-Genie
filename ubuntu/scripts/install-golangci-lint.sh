#!/bin/bash
# For local installation, binary will be $(go env GOPATH)/bin/golangci-lint
#curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin

# OR for system-wide installation (only if go was installed in /usr/local/go/bin)
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sudo sh -s -- -b /usr/local/go/bin

echo "Installed golangci-lint. Run with:"
echo "$ make lint"