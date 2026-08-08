# 音乐播放器发光效果 Pro v2.0.0

## 新增功能

### 🎵 频谱特效
- 实时音频频谱可视化效果
- 支持镜像模式（从中间向上下扩展）
- 可调节条带数量（6-32条）
- 可调节灵敏度
- 渐变色彩效果
- 音乐播放时动态跳动，暂停时缓慢回落
- 发光阴影效果

### ✨ 灵动光圈
四种光圈样式可选：
1. **渐变旋转** - 彩色渐变光圈持续旋转，带呼吸效果
2. **呼吸脉冲** - 光圈有节奏地呼吸脉动，外层扩散波纹
3. **双色追逐** - 两个彩色光弧相互追逐
4. **星光闪烁** - 环绕的星光点交替闪烁

可调节参数：
- 光圈宽度
- 发光强度
- 旋转速度
- 脉动速度

## 项目结构

```
musicfg_pro/
├── Makefile                    # 主Makefile
├── control                     # 包信息
├── Tweak.xm                    # 主Tweak代码
├── SpectrumView.h              # 频谱视图头文件
├── SpectrumView.mm             # 频谱视图实现
├── AuroraRingView.h            # 灵动光圈头文件
├── AuroraRingView.mm           # 灵动光圈实现
├── prefs/                      # 设置bundle
│   ├── Makefile
│   ├── MFGRootListController.m # 设置控制器
│   ├── Info.plist
│   ├── entry.plist
│   ├── Root.plist              # 设置项定义
│   └── icon*.png
└── layout/                     # 安装布局
    └── var/jb/Library/
        ├── MobileSubstrate/DynamicLibraries/
        │   ├── musicfg.dylib   (编译后生成)
        │   └── musicfg.plist
        ├── PreferenceBundles/musicfg.bundle/
        │   ├── Root.plist
        │   └── icon*.png
        └── PreferenceLoader/Preferences/
            └── musicfg.plist
```

## 编译方法

### 环境要求
- Theos 开发环境
- iOS SDK 15.0+
- 支持 arm64 / arm64e

### 编译步骤

```bash
# 1. 进入项目目录
cd musicfg_pro

# 2. 编译
make package

# 3. 安装到设备（需配置THEOS_DEVICE_IP）
make install
```

### 或者手动编译

```bash
# 编译Tweak
make

# 打包deb
make package
```

## 设置项说明

### 播放器效果
- 启用效果 - 总开关
- 圆角半径 - 播放器圆角大小
- 边框宽度 - 发光边框宽度
- 阴影偏移 - 阴影垂直偏移
- 阴影范围 - 阴影模糊半径
- 动画速度 - 颜色动画速度

### 频谱特效
- 启用频谱特效 - 开关
- 条带数量 - 频谱条数量（6-32）
- 灵敏度 - 动画剧烈程度
- 条宽 - 单个频谱条宽度
- 镜像模式 - 是否从中间向上下扩展

### 灵动光圈
- 启用灵动光圈 - 开关
- 样式 - 四种样式选择
- 宽度 - 光圈线条宽度
- 强度 - 发光强度
- 旋转速度 - 旋转动画速度
- 脉动速度 - 呼吸脉动速度

### 颜色预设
- 彩色动画颜色 - 自定义渐变色（十六进制，逗号分隔）
  例如：`#FF0000,#00FF00,#0000FF`

## 技术实现

### 频谱动画原理
由于SpringBoard进程无法直接访问音乐APP的音频数据，采用**模拟频谱**方案：
- 使用多个正弦波叠加模拟真实频谱分布
- 每个频谱条有独立的相位和速度
- 中间频率高，两边频率低（符合真实频谱特征）
- 监听系统音乐播放状态，播放时活跃，暂停时回落

### 光圈动画原理
- 使用 CoreAnimation 实现高性能动画
- CADisplayLink 保证60fps流畅度
- CAGradientLayer 实现渐变效果
- CAReplicatorLayer 可用于复制效果
- CAShapeLayer 绘制圆形路径

## 兼容性

- 支持 iOS 15.0 - 17.x
- 支持 Dopamine 无根越狱
- 支持 checkra1n / unc0ver 等有根越狱
- 支持 arm64 / arm64e 设备

## 注意事项

1. 首次安装后需要注销（Respring）生效
2. 修改设置后部分选项需要注销生效
3. 如果不显示效果，请确认音乐播放器正在播放
4. 建议配合系统音乐播放器或主流音乐APP使用
5. 如遇性能问题，可适当减少频谱条数量

## 版本历史

### v2.0.0
- 新增频谱特效功能
- 新增灵动光圈功能
- 新增四种光圈样式
- 优化动画性能
- 完善设置界面

### v1.0.0
- 基础发光效果
- 边框颜色动画
- 阴影颜色动画
- 自定义颜色预设
