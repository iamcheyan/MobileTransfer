## 📦 MobileTransfer

日本語 | English | 简体中文

### 日本語

本プロジェクトは [砍砍@标准件厂长（Lakr Aream）](https://github.com/Lakr233) のオープンソースをベースに開発しています。  
© 2024 砍砍@标准件厂长 All Rights Reserved.

このリポジトリは [iamcheyan](https://github.com/iamcheyan) による fork です。

#### このブランチの変更
- 上流が OSS 化されたため、アクティベーション機能を削除し、そのまま利用可能
- 既知の不具合の修正
- 日本語ローカライズの追加（Language メニューで 中文 / English / 日本語 / Auto を切替）
- 最新の macOS に継続対応

#### 上流の機能（要約）
- iOS デバイスのバックアップと復元
- [BBackupp](https://github.com/Lakr233/BBackupp) からのバックアップ変換
- アプリのバックアップ/復元（実験的。API 変更の影響で動作しない場合あり）
- バックアップパスワードの設定
- 任意パスへのバックアップ／任意パスからの復元
- 増分バックアップ（Menu -> Backup -> Load Checkpoint）

#### スクリーンショット
![Screenshot](./Resources/Screenshot.png)

#### ビルドと実行
1. Xcode で `MobileTransfer.xcworkspace` を開く
2. ターゲット `MobileTransfer` を選択して Build & Run

#### 言語とローカライズ
- サポート: `en`、`zh-Hans`、`ja`
- アプリ内の `Language` メニュー、または `Auto (System)` でシステムに追従

#### 著作権と謝辞
- 原作と主要な実装は上流作者 砍砍@标准件厂长（Lakr Aream） に帰属します
- 上流プロジェクト: [Lakr233/MobileTransfer](https://github.com/Lakr233/MobileTransfer)

#### ライセンス
MIT。詳細は [LICENSE](./LICENSE) を参照してください。

— 原作 © 砍砍@标准件厂长 / 本バージョンのメンテナンス: [iamcheyan](https://github.com/iamcheyan)

---

### English

This project is based on the open-source work by [Lakr Aream](https://github.com/Lakr233).  
© 2024 Lakr Aream. All Rights Reserved.

This repository is a fork maintained by [iamcheyan](https://github.com/iamcheyan).

#### Changes in this fork
- Activation flow removed (since the upstream is open-sourced) — usable out of the box
- Bug fixes from the original project
- Added Japanese localization (switch via Language menu: Chinese / English / Japanese / Auto)
- Ongoing compatibility with latest macOS versions

#### Upstream features (summary)
- Backup and restore iOS devices
- Convert backups from [BBackupp](https://github.com/Lakr233/BBackupp)
- App backup/restore (experimental; may not work due to API changes)
- Set backup password
- Backup to a custom path and restore from it
- Incremental backup (Menu -> Backup -> Load Checkpoint)

#### Screenshot
![Screenshot](./Resources/Screenshot.png)

#### Build & Run
1. Open `MobileTransfer.xcworkspace` in Xcode
2. Select target `MobileTransfer`, then Build & Run

#### Localization
- Supported: `en`, `zh-Hans`, `ja`
- Switch in-app via `Language` menu or follow system with `Auto (System)`

#### Credits
- Original work by Lakr Aream
- Upstream: [Lakr233/MobileTransfer](https://github.com/Lakr233/MobileTransfer)

#### License
MIT. See [LICENSE](./LICENSE).

— Original © Lakr Aream · This fork maintained by [iamcheyan](https://github.com/iamcheyan)

---

### 简体中文

本项目基于 [砍砍@标准件厂长（Lakr Aream）](https://github.com/Lakr233) 的开源代码进行开发。  
© 2024 砍砍@标准件厂长 版权所有。

本仓库为 [iamcheyan](https://github.com/iamcheyan) 的 fork 版本。

#### 本分支改动
- 由于原版本已开源，本分支去除了激活功能，可直接使用
- 修复原项目中的部分问题
- 增加日语本地化支持（Language 菜单内可切换：中文 / English / 日本語 / Auto）
- 持续兼容最新 macOS 版本

#### 原项目功能（汇总自上游说明）
- 备份与恢复 iOS 设备数据
- 从 [BBackupp](https://github.com/Lakr233/BBackupp) 转换备份
- 备份/恢复 App（实验性，受 API 变更影响可能不可用）
- 设置备份密码
- 自定义路径备份并从该路径恢复
- 增量备份（菜单 -> Backup -> Load Checkpoint）

#### 截图
![Screenshot](./Resources/Screenshot.png)

#### 构建与运行
1. 使用 Xcode 打开 `MobileTransfer.xcworkspace`
2. 选择目标 `MobileTransfer`，直接 Build & Run

#### 语言与本地化
- 已支持：`en`、`zh-Hans`、`ja`
- 应用内通过菜单 `Language` 切换；也可选择 `Auto (System)` 跟随系统

#### 版权与致谢
- 原作与主要工作来自上游仓库作者：砍砍@标准件厂长（Lakr Aream）
- 如需查看原始项目，请访问：[Lakr233/MobileTransfer](https://github.com/Lakr233/MobileTransfer)

#### 许可证
遵循 MIT 协议，详见 [LICENSE](./LICENSE)。

— 原作 © 砍砍@标准件厂长 · 本版本维护更新： [iamcheyan](https://github.com/iamcheyan)
