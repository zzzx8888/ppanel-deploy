# PPanel 在线升级仓库地址修改指南 (公共仓库版)

由于你已将仓库设置为公共（Public），在线升级检测现在可以使用更高效的 jsDelivr CDN 方式。我已经为你更新了代码，将所有检测点指向了你的公共仓库。

## 1. 修改 Server 端 (ppanel-server)

Server 端通过硬编码的常量来定义其代码仓库地址，并在网关模式下将其报告给网关模块。

### 修改位置
文件路径：[version.go](file:///c:/Users/aituy/Desktop/project/s/ppanel-server/pkg/constant/version.go)

### 修改操作
找到以下代码行并将其修改为你自己的仓库地址：

```go
// ppanel-server/pkg/constant/version.go

var (
	Version     = "unknown version"
	BuildTime   = "unknown time"
	Repository  = "https://github.com/zzzx8888/ppanel-server" // 已更新为你的仓库
	ServiceName = "ApiService"
)
```

---

## 2. 修改 Web 端 (ppanel-web)

Web 端的管理后台通过 jsDelivr API 快速检测最新版本，并生成对应的 GitHub 下载链接。

### 修改位置
文件路径：[system-version-card.tsx](file:///c:/Users/aituy/Desktop/project/s/ppanel-web/apps/admin/components/dashboard/system-version-card.tsx)

### 修改操作

我已经为你完成了以下逻辑的更新：

#### A. 版本检测 API (使用 jsDelivr)
代码现在会从 jsDelivr 获取你仓库的最新版本号，这种方式比直接调用 GitHub API 更快且无频率限制：
- Web: `https://data.jsdelivr.com/v1/packages/gh/zzzx8888/ppanel-web/resolved?specifier=latest`
- Server: `https://data.jsdelivr.com/v1/packages/gh/zzzx8888/ppanel-server/resolved?specifier=latest`

#### B. 发布链接地址
当检测到新版本时，跳转链接会自动指向你的仓库 Release 页面：
- `https://github.com/zzzx8888/ppanel-web/releases/tag/v{version}`
- `https://github.com/zzzx8888/ppanel-server/releases/tag/v{version}`

---

## 3. 设置 GitHub Release 功能

为了让程序能够识别到“新版本”，请确保你的发布流程符合以下规范：

1. **Tag 命名**：发布时使用的 Tag 必须以 `v` 开头，且符合语义化版本，例如 `v1.6.4`。
2. **发布流程**：
   - 在你的 GitHub 仓库点击 **Releases** -> **Create a new release**。
   - 创建一个新的 Tag（如 `v1.6.4`）。
   - 填写标题并发布。
3. **生效时间**：jsDelivr CDN 通常会有几分钟的缓存延迟。发布后，管理后台可能需要稍等片刻才会显示新版本。

## 注意事项

- **无需 Token**：由于仓库是公共的，你不再需要在前端代码中配置 GitHub Token，也不受私有仓库的访问限制。
- **开源合规**：请注意，Fork 后的公共仓库依然遵循原项目的开源协议。
