# TrollStore 界面重构
这是一个经过汉化和UI优化的TrollStore版本，致力于为中文用户提供更好的使用体验。本项目基于[opa334的TrollStore](https://github.com/opa334/TrollStore)开发，保留了原版的全部功能，并增加了完整的中文本地化支持和UI改进。

## 功能特点

### 完整的中文界面

- 所有菜单、设置项和提示信息均已翻译为中文
- 优化了中文字体显示和排版，确保在各种屏幕尺寸下有良好的显示效果
- 修复了原版在显示中文时可能出现的布局问题

### 新的主界面设计

- 实现了全新的现代化界面设计，包括渐变动画背景和卡片式UI
- 添加了更直观的应用安装和管理流程
- 改进了状态指示和信息展示，使用户能够更清晰地了解当前系统状态

### 设置界面优化

- 完全重构了设置界面，使用新的分组和卡片设计
- 改进了设置项的布局和交互方式，使设置更易于访问和修改
- 为不同类型的设置项（开关、按钮、分段控制器等）添加了统一的样式和行为

### 代码结构改进

- 引入了TSPresentationDelegate模式，统一处理视图控制器的展示
- 改进了设置项的管理和处理方式，使代码更加模块化和可维护
- 优化了应用启动和资源加载流程，提高应用性能

## 安装方法

1. 下载最新的[TrollStore-FixedZH.ipa](https://github.com/Lincb522/TrollStore/releases/latest)文件
2. 使用以下方式之一安装:
   - 如果你已经安装了TrollStore，直接通过TrollStore安装IPA文件
   - 如果你还没有安装TrollStore，请按照[官方安装指南](https://github.com/opa334/TrollStore#installation)进行安装

## 构建说明

如果你想自己编译此项目:

1. 确保已安装Theos开发环境
2. 克隆此仓库：`git clone https://github.com/Lincb522/TrollStore.git`
3. 进入项目目录: `cd TrollStore`
4. 编译项目: `make`
5. 生成IPA文件: `./package_ipa.sh`

## 截图

(此处将添加应用截图)

## 致谢

- [opa334](https://github.com/opa334) - 原版TrollStore的开发者
- 所有为原版TrollStore做出贡献的开发者
- Google TAG、@alfiecg_dev - CoreTrust漏洞发现
- 所有参与测试和反馈的用户

## 许可证

本项目采用与原版TrollStore相同的许可证 - [LICENSE](LICENSE)

