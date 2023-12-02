#!/bin/bash

export VERSION=$1
export SIGNER=$2
export PROGRAM_NAME=$3

print_usageInfoAndExit() {
    echo "Usage: ./build.sh <VERSION TAG> <GPG SIGNER ID> <PROGRAM NAME>"
    exit 1
}

if [ -z "$VERSION" ]; then
    echo "VERSION TAG is not defined"
    print_usageInfoAndExit
fi

if [ -z "$SIGNER" ]; then
    echo "GPG SIGNER ID is not defined"
    print_usageInfoAndExit
fi

if [ -z "$PROGRAM_NAME" ]; then
    echo "PROGRAM NAME is not defined"
    print_usageInfoAndExit
fi

build_go_program() {
    currentDateTime=$(date '+%Y-%m-%d@%H:%M:%S-%Z')
    builderArch=$(uname -m)
    builderOS=$(uname -s)

    echo "Building for ${GOOS} ${GOARCH}"

    go build -ldflags "-X main.version=${VERSION} -X main.metaBuildTime=${currentDateTime} -X main.metaBuilderOS=${builderOS} -X main.metaBuilderArch=${builderArch}" -o bin/${PROGRAM_NAME}_${VERSION}_${GOOS}_${GOARCH}
    checksum=$(sha256sum bin/${PROGRAM_NAME}_${VERSION}_${GOOS}_${GOARCH} | awk '{print $1}')
    
    echo "${checksum} - ${PROGRAM_NAME}_${VERSION}_${GOOS}_${GOARCH}" >> "./bin/SHA256SUMS"
}

clean_bin() {
    echo "Cleaning bin dir"
    rm -r "./bin"
    mkdir "./bin"
}



clean_bin

touch "./bin/SHA256SUMS"

# For Linux (64-bit)
GOOS=linux GOARCH=amd64
build_go_program

# For Windows (64-bit)
GOOS=windows GOARCH=amd64
build_go_program

# For FreeBSD (64-bit)
GOOS=freebsd GOARCH=amd64
build_go_program

gpg --armor --detach-sign --output "./bin/SHA256SUMS.asc" --default-key "$SIGNER" ./bin/SHA256SUMS
