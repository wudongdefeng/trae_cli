# trae-proxy CI 配置（含 linux/arm64 构建）

给 [DASungta/trae-proxy](https://github.com/DASungta/trae-proxy) 补上 **Linux ARM64（aarch64）** 产物的 CI 配置。

## 为什么需要它 

上游仓库的 Release 只发布 4 个产物：

```
trae-proxy-darwin-amd64
trae-proxy-darwin-arm64      ← 这是 macOS (Apple Silicon)，不是 Linux ARM
trae-proxy-linux-amd64
trae-proxy-windows-amd64.exe
```

全部 28 个 release（v0.1.0 ~ v0.4.10）都**没有** `linux-arm64` 包，其 `install.sh` 里也有硬编码拦截：

```sh
if [ "$OS" = "linux" ] && [ "$ARCH" = "arm64" ]; then
  fatal "暂不支持 linux-arm64，请使用 x86_64 机器"
fi
```

项目本身是纯 Go（依赖 survey / cobra / toml，无 cgo），交叉编译毫无障碍，只是 CI 没编这个平台。

## 文件说明

| 文件 | 放置位置 | 改动 |
| --- | --- | --- |
| `Makefile` | 仓库根目录 | `build-all` 增 linux/arm64 一行（带 `CGO_ENABLED=0`）；`release` 清单同步增加 |
| `.github/workflows/release.yml` | 同路径覆盖 | Release 上传清单增加 `bin/trae-proxy-linux-arm64` |

原文件其余 target（`build` / `install` / `test` / `clean` 等）均未改动。

## 用法

### 方式一：覆盖到你自己的 fork

```bash
git clone https://github.com/<你>/trae-proxy.git
cd trae-proxy
cp /path/to/trae-proxy-ci-repo/Makefile .
cp /path/to/trae-proxy-ci-repo/.github/workflows/release.yml .github/workflows/
git add Makefile .github/workflows/release.yml
git commit -m "ci: build linux/arm64"
git tag v0.4.11
git push origin main --tags
```

### 方式二：直接把本仓库当构建工程

适用于不想 fork、只想拿到 ARM 二进制的场景。把上游源码放进 `src/` 后执行：

```bash
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 \
  go build -trimpath -ldflags "-s -w -X main.version=v0.4.11" \
  -o bin/trae-proxy-linux-arm64 ./src/cmd/trae-proxy
```

## 产物地址

推 tag 后 Actions 自动发布，下载链接：

```
https://github.com/<你>/trae-proxy/releases/download/v0.4.11/trae-proxy-linux-arm64
```

## 校验清单

- [x] YAML 可解析，`permissions.contents: write` 齐备（否则发 Release 会 403）
- [x] Makefile 新行以 TAB 开头（用空格会 `missing separator`）
- [x] `make -n build-all` 五条交叉编译命令正确展开
- [x] 编出的 5 个平台产物与 Release 上传清单一一对应
- [x] `checksums.txt` 用 `trae-proxy-*` 通配，自动覆盖新产物

## 注意

`install.sh` 中的 arm64 拦截**未包含在本仓库中**（上游未提供完整文件内容，不做臆造）。装 ARM 包时请手动 `chmod +x` 使用，或自行删除该判断。
