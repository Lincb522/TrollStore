# TrollStore 项目分析

TrollStore 是一个永久签名的越狱应用程序，可以永久安装任何 IPA 文件，无需开发者账号或其他签名工具。

## 项目概述

TrollStore 利用了 iOS 系统中的 AMFI/CoreTrust 漏洞，使 iOS 无法正确验证包含多个签名者的二进制文件的代码签名。通过这个漏洞，TrollStore 可以安装具有任何权限的应用程序。

**支持版本**：iOS 14.0 beta 2 - 16.6.1, 16.7 RC (20H18), 17.0

## 项目结构

TrollStore 项目由以下主要组件组成：

1. **TrollStore** - 主应用程序
   - 负责用户界面和应用程序管理
   - 处理IPA文件的安装和卸载
   - 提供设置和配置选项

2. **RootHelper** - 权限助手
   - 以root权限执行各种操作
   - 处理应用程序的安装、卸载和权限管理
   - 管理应用程序注册状态

3. **TrollHelper** - 持久性助手
   - 确保TrollStore在系统图标缓存重新加载后仍能正常工作
   - 在iOS 14上作为持久性helper应用

4. **Exploits** - 漏洞利用模块
   - fastPathSign：实现CoreTrust漏洞利用
   - 用于绕过iOS的签名限制

5. **Shared** - 共享工具类
   - TSUtil：提供各种实用功能
   - 包含应用程序共享的组件

6. **TrollStoreLite** - 精简版本
   - 专为已越狱设备设计的精简版本
   - 依赖于现有的越狱环境，不需要利用CoreTrust漏洞
   - 提供与完整版相同的应用安装功能

## 主要功能

1. **应用程序安装**
   - 可以安装任何IPA文件，无需开发者签名
   - 支持通过URL远程安装应用程序
   - 处理应用程序权限和配置

2. **应用程序管理**
   - 查看和管理已安装的应用程序
   - 卸载应用程序
   - 修改应用程序的注册状态

3. **权限管理**
   - 允许应用程序获取特殊权限
   - 支持无沙盒运行
   - 可以作为root用户运行二进制文件

4. **JIT支持**
   - 支持为应用程序启用JIT（即时编译）
   - 通过URL方案快速启用JIT

5. **持久性**
   - 使用持久性助手确保TrollStore在系统重启后仍能工作
   - 防止图标缓存刷新导致的应用程序失效

## 技术特点

1. **使用Objective-C开发**
   - 主要使用Objective-C开发，适合iOS系统级应用
   - 利用iOS私有API实现高级功能

2. **权限提升**
   - 利用CoreTrust漏洞获取系统权限
   - 可以为应用程序添加特殊权限

3. **签名技术**
   - 使用假证书签名应用程序
   - 保留应用程序原有的权限声明

4. **URL方案**
   - 使用"apple-magnifier://"URL方案进行应用安装和JIT启用
   - 避免被检测为越狱工具

## 构建与安装

TrollStore项目使用Theos构建系统进行编译，主要构建流程如下：

1. **环境准备**
   - 安装theos开发环境
   - 安装brew和libarchive依赖

2. **构建流程**
   - 构建fastPathSign工具：用于绕过签名限制
   - 构建RootHelper：提供root权限支持
   - 构建TrollStore主应用
   - 构建TrollHelper嵌入式助手
   - 生成最终的安装包

3. **安装方式**
   - 根据不同iOS版本有不同的安装方法
   - 使用特定的漏洞进行初始安装
   - 通过持久性助手保持应用可用

4. **TrollStoreLite安装**
   - 在已越狱设备上，可以直接安装TrollStoreLite
   - 需要ldid依赖
   - 提供与完整版相同的功能，但不需要利用CoreTrust漏洞

## 版本区别

1. **TrollStore (完整版)**
   - 适用于未越狱设备
   - 利用CoreTrust漏洞实现应用安装
   - 需要特定的iOS版本

2. **TrollStoreLite (精简版)**
   - 适用于已越狱设备
   - 依赖现有越狱环境获取权限
   - 可能支持更广泛的iOS版本

## 用户使用指南

### 安装TrollStore

1. **初次安装**
   - 根据设备iOS版本，参考[ios.cfw.guide](https://ios.cfw.guide/installing-trollstore)的安装指南
   - 不同iOS版本可能需要不同的安装方法
   - iOS 16.7.x（不包括16.7 RC）和17.0.1+版本不受支持

2. **应用安装**
   - 在TrollStore中打开IPA文件
   - 通过"apple-magnifier://install?url=<IPA_URL>"URL方案远程安装
   - 可以设置自动安装或显示安装确认提示

3. **应用管理**
   - 在"Apps"选项卡中查看和管理已安装的应用
   - 通过点击或左滑应用卸载
   - 只能从TrollStore中卸载通过TrollStore安装的应用

4. **持久性助手**
   - 在iOS重新加载图标缓存后，需要使用持久性助手恢复TrollStore功能
   - 在TrollStore设置中设置持久性助手
   - iOS 14上使用TrollHelper作为持久性助手

### 更新TrollStore

1. **自动更新**
   - 当有新版本可用时，TrollStore设置中会显示更新按钮
   - 点击按钮，TrollStore会自动下载、安装更新并刷新系统

2. **手动更新**
   - 下载Releases中的TrollStore.tar文件
   - 在TrollStore中打开它进行更新

3. **兼容性注意**
   - 每次更新前应检查支持的设备和iOS版本
   - 某些iOS版本可能永远不受支持

## 改进建议

根据项目分析，以下是一些可能的改进方向：

1. **用户界面优化**
   - 改进应用程序管理界面，添加批量操作功能
   - 添加应用分类和搜索功能
   - 优化应用安装流程，提供更详细的进度显示

2. **功能扩展**
   - 添加应用备份和恢复功能
   - 支持应用数据管理
   - 提供更多应用权限自定义选项

3. **安全性增强**
   - 添加应用安装来源验证
   - 提供应用权限审查功能
   - 增强错误处理和异常恢复机制

4. **兼容性扩展**
   - 尝试寻找新的漏洞以支持更多iOS版本
   - 优化对旧设备的支持
   - 提高应用安装成功率

5. **开发者工具**
   - 添加调试工具集成
   - 提供应用开发测试辅助功能
   - 增加权限分析工具

## 局限性

TrollStore无法实现的功能：
- 获取完整的平台化权限（`TF_PLATFORM` / `CS_PLATFORMIZED`）
- 生成启动守护进程（需要`CS_PLATFORMIZED`）
- 向系统进程注入补丁（需要`TF_PLATFORM`以及其他绕过）

## 总结

TrollStore是一个强大的iOS应用安装工具，它利用系统漏洞允许用户安装未签名或自签名的应用程序，并赋予这些应用程序特殊权限。该项目结构清晰，功能强大，实现了iOS上应用程序签名限制的完全绕过。

项目的技术实现十分精巧，通过利用CoreTrust漏洞绕过了iOS的签名限制，同时通过持久性助手确保了应用程序的持续可用。对于开发者和用户来说，TrollStore提供了一种在没有开发者账号的情况下安装和测试应用程序的方法，极大地方便了iOS应用的开发和测试。

虽然TrollStore有一些局限性，但它仍然是目前最强大的非越狱iOS应用安装解决方案，为iOS用户提供了更多的自由和可能性。随着iOS系统的不断更新，TrollStore也需要不断适应和发展，以继续为用户提供优质的服务。 