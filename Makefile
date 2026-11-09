# 自动检测源码位置：优先根目录 go.mod，其次 src/go.mod
ifneq ($(wildcard go.mod),)
    SRC_ROOT := .
    PKG := ./cmd/trae-proxy
else ifneq ($(wildcard src/go.mod),)
    SRC_ROOT := src
    PKG := ./cmd/trae-proxy
else
    $(error "未找到 go.mod，请将源码放在仓库根目录或 src/ 子目录下")
endif

VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
LDFLAGS := -X main.version=$(VERSION)
OUT := bin/trae-proxy

.PHONY: build build-all install uninstall test clean checksums release

BIN := $(CURDIR)/bin

build:
	cd $(SRC_ROOT) && go build -ldflags "$(LDFLAGS)" -o $(BIN)/trae-proxy $(PKG)

build-all:
	cd $(SRC_ROOT) && mkdir -p $(BIN) && \
	  GOOS=darwin  GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o $(BIN)/trae-proxy-darwin-arm64       $(PKG) && \
	  GOOS=darwin  GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o $(BIN)/trae-proxy-darwin-amd64       $(PKG) && \
	  GOOS=linux   GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o $(BIN)/trae-proxy-linux-amd64        $(PKG) && \
	  GOOS=linux   CGO_ENABLED=0 GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o $(BIN)/trae-proxy-linux-arm64 $(PKG) && \
	  GOOS=windows GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o $(BIN)/trae-proxy-windows-amd64.exe  $(PKG)

checksums: build-all
	cd bin && sha256sum trae-proxy-* > checksums.txt

release: checksums
	@if [ "$(VERSION)" = "dev" ]; then echo "Error: 请先打 tag (git tag vX.Y.Z)"; exit 1; fi
	@echo "Creating GitHub release $(VERSION)..."
	gh release create $(VERSION) \
		bin/trae-proxy-darwin-arm64 \
		bin/trae-proxy-darwin-amd64 \
		bin/trae-proxy-linux-amd64 \
		bin/trae-proxy-linux-arm64 \
		bin/trae-proxy-windows-amd64.exe \
		bin/checksums.txt \
		--title "$(VERSION)" \
		--generate-notes

install: build
	sudo cp $(OUT) /usr/local/bin/trae-proxy
	@echo "installed to /usr/local/bin/trae-proxy"

uninstall:
	sudo rm -f /usr/local/bin/trae-proxy
	@echo "removed /usr/local/bin/trae-proxy"

test:
	cd $(SRC_ROOT) && go test -v -race ./...

clean:
	rm -rf bin/
