## 📦 MobileTransfer

本项目基于 [砍砍@标准件厂长（Lakr Aream）](https://github.com/Lakr233) 的开源代码进行开发。  
© 2024 砍砍@标准件厂长 版权所有。

本仓库为 [iamcheyan](https://github.com/iamcheyan) 的 fork 版本，主要维护与更新：  
由于原版本已开源，本分支去除了激活功能，可直接使用。

### 本分支改动
- 修复原项目中的部分问题
- 增加日语本地化支持（Language 菜单内可切换：中文 / English / 日本語 / Auto）
- 持续兼容最新 macOS 版本

### 原项目功能（汇总自上游说明）
- 备份与恢复 iOS 设备数据
- 从 [BBackupp](https://github.com/Lakr233/BBackupp) 转换备份
- 备份/恢复 App（实验性，受 API 变更影响可能不可用）
- 设置备份密码
- 自定义路径备份并从该路径恢复
- 增量备份（菜单 -> Backup -> Load Checkpoint）

### 截图
![Screenshot](./Resources/Screenshot.png)

### 构建与运行
1. 使用 Xcode 打开 `MobileTransfer.xcworkspace`
2. 选择目标 `MobileTransfer`，直接 Build & Run

### 语言与本地化
- 已支持：`en`、`zh-Hans`、`ja`
- 应用内通过菜单 `Language` 切换；也可选择 `Auto (System)` 跟随系统

### 版权与致谢
- 原作与主要工作来自上游仓库作者：砍砍@标准件厂长（Lakr Aream）
- 如需查看原始项目，请访问：[Lakr233/MobileTransfer](https://github.com/Lakr233/MobileTransfer)

### 许可证
遵循 MIT 协议，详见 [LICENSE](./LICENSE)。

—

原作 © 砍砍@标准件厂长 · 本版本维护更新： [iamcheyan](https://github.com/iamcheyan)
