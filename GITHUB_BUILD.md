# GitHub 编译使用说明

## 快速开始

### 1. 创建 GitHub 仓库

1. 在 GitHub 上创建一个新仓库
2. 将本项目所有文件上传到仓库

### 2. 启用 Actions

1. 进入仓库的 **Actions** 标签页
2. 点击 "I understand my workflows, go ahead and enable them"

### 3. 手动触发编译

1. 进入 **Actions** → **Build Tweak**
2. 点击 **Run workflow**
3. 选择分支，点击运行

### 4. 下载编译产物

编译完成后：
1. 进入对应的工作流运行页面
2. 滚动到 **Artifacts** 区域
3. 点击 `musicfg_xxx` 下载 deb 包

## 自动编译触发条件

- **推送代码** 到 main/master 分支时自动编译
- **提交 PR** 时自动编译
- **打标签** `v*` 时自动创建 Release 并上传 deb

## 打标签发布版本

```bash
# 打标签
git tag v2.0.0
git push origin v2.0.0
```

推送标签后，GitHub Actions 会自动：
1. 编译项目
2. 创建 Release
3. 将 deb 包上传到 Release 附件

## 工作流配置

工作流文件位置：`.github/workflows/build.yml`

### 包含功能
- ✅ Theos 环境自动搭建
- ✅ iOS 16.5 SDK 自动下载
- ✅ 缓存加速（Theos 和 SDK 都会缓存）
- ✅ 自动编译打包
- ✅ 产物自动上传
- ✅ Tag 自动发布 Release

### 运行环境
- macOS 13
- Theos (最新版)
- iPhoneOS 16.5 SDK
- dpkg + ldid

## 常见问题

### Q: 编译失败怎么办？
A: 查看 Actions 日志，根据错误信息排查。常见问题：
- 代码语法错误
- 缺少依赖库
- SDK 版本不匹配

### Q: 如何修改 SDK 版本？
A: 编辑 `.github/workflows/build.yml`，修改 `matrix` 中的 `sdk` 和 `sdk_url`。

### Q: 编译太慢怎么办？
A: 第二次编译会快很多，因为 Theos 和 SDK 都被缓存了。

## 本地编译（可选）

如果你想在本地编译：

```bash
# 安装Theos（参考官方文档）
# 然后：
make package
```

产物在 `packages/` 目录下。
