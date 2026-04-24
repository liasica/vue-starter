---
name: vue-starter-init
description: Use when the user wants to scaffold, bootstrap, create, or initialize a new Vue 3 project — including requests like "初始化 vue3 项目"、"新建 vue 工程"、"create a vue project"、"scaffold vue 3 with UnoCSS/Tailwind"、"set up a new vue starter"。适用于需要带有 ESLint、Stylelint、UnoCSS 或 Tailwind CSS 预设的 Vue 3 + Vite + TypeScript 项目初始化场景。
user-invocable: false
allowed-tools: Bash(curl -fsSL https://raw.githubusercontent.com/liasica/vue-starter/*)
---

# Vue Starter Init

使用 `liasica/vue-starter` 一键初始化带有完整 lint/style 预设的 Vue 3 项目。

## Overview

`vue-starter` 封装了 `pnpm create vue@latest` + 一组默认 dev 依赖 + ESLint/Stylelint/Vite/CSS 方案配置文件的写入，最终产出可直接开发的 Vue 3 + Vite + TypeScript 工程。

**核心产物：**
- 由 `create-vue` 交互式生成的项目骨架
- 已安装并配置好的 ESLint（含 `@stylistic`、`eslint-plugin-vue`、`oxlint`、可选 `@unocss/eslint-config`）
- 已安装并配置好的 Stylelint（SCSS + Vue + `@stylistic/stylelint-plugin`）
- `vite.config.ts`、`uno.config.ts`（UnoCSS）或 `src/assets/main.css`（Tailwind）
- 样式方案二选一：**UnoCSS** 或 **Tailwind CSS**

## When to Use

- 用户请求初始化/新建/scaffold 一个 Vue 3 项目
- 用户提到 `vue-starter`、`create-vue`、"vue 模板"、"vue 脚手架"
- 用户希望项目自带 ESLint + Stylelint + UnoCSS/Tailwind 预设
- 当前工作目录为空，且用户意图是建立新 Vue 工程

**不适用：**
- 已存在的 Vue 项目要添加某个依赖 —— 直接用 `pnpm add` 即可
- 非 Vue 项目（React/Nuxt/SSR）
- 用户想完全自定义脚手架流程，不接受预设配置

## Quick Reference

| 场景 | 命令 |
|------|------|
| 完全交互式（推荐） | `curl -fsSL https://raw.githubusercontent.com/liasica/vue-starter/master/install.sh \| bash` |
| 指定项目目录名 | `curl -fsSL https://raw.githubusercontent.com/liasica/vue-starter/master/install.sh \| bash -s -- my-app` |
| 指定项目名 + Tailwind | `curl -fsSL https://raw.githubusercontent.com/liasica/vue-starter/master/install.sh \| bash -s -- my-app tailwind` |
| 指定项目名 + UnoCSS | `curl -fsSL https://raw.githubusercontent.com/liasica/vue-starter/master/install.sh \| bash -s -- my-app unocss` |

## Usage Flow

1. **确认前置条件**
   - 已安装 `pnpm`（脚本内部使用 `pnpm create vue@latest` 与 `pnpm install -D`）
   - 当前所在目录是希望创建项目的父目录（项目会创建在 `pwd/<project-name>` 下）
   - 终端可交互（`create-vue` 阶段需要 TTY 回答项目名与特性问题）

2. **执行脚本**

   在你希望存放新项目的父目录中运行：

   ```bash
   curl -fsSL https://raw.githubusercontent.com/liasica/vue-starter/master/install.sh | bash
   ```

   如果用户已经指定了项目名和样式方案，直接传参避免额外交互：

   ```bash
   curl -fsSL https://raw.githubusercontent.com/liasica/vue-starter/master/install.sh | bash -s -- my-app tailwind
   ```

3. **让 `create-vue` 负责框架问题**
   - 脚本不会替用户回答 `create-vue` 的任何问题（TypeScript/Router/Pinia/Vitest 等）
   - 让用户按需勾选即可

4. **样式方案选择**
   - 如果第二个参数已给定 `tailwind` 或 `unocss`，跳过菜单
   - 否则脚本会弹出交互菜单（`←/→`、`↑/↓`、`h/j/k/l`、`1/2`、空格切换，回车确认），**默认高亮 Tailwind CSS**

5. **脚本自动完成的收尾**
   - `pnpm install -D` 写入 lint/style 相关 devDependencies
   - 生成/覆盖 `vite.config.ts`
   - 写入 `eslint.config.ts`、`stylelint.config.js`、`.stylelintignore`
   - Tailwind → 写入 `src/assets/main.css`；UnoCSS → 写入 `uno.config.ts`

## Arguments Reference

| 位置 | 名称 | 可选值 | 说明 |
|------|------|--------|------|
| `$1` | `project_name` | 任意合法目录名 | 留空则由 `create-vue` 交互询问 |
| `$2` | `style_solution` | `tailwind` \| `tailwindcss` \| `unocss` \| `uno` | 留空则弹出交互菜单（默认高亮 Tailwind）；大小写不敏感 |

## Expected Result

脚本成功执行后，在 `$(pwd)/<project-name>` 目录下可见：

```
my-app/
├── eslint.config.ts
├── stylelint.config.js
├── .stylelintignore
├── vite.config.ts
├── src/assets/main.css    # Tailwind 方案
├── uno.config.ts          # UnoCSS 方案
├── package.json
├── src/
└── ...（create-vue 生成的其余文件）
```

后续用户可运行：

```bash
cd my-app
pnpm dev       # 启动开发服务器
pnpm lint      # 运行 ESLint
pnpm build     # 生产构建
```

## Common Mistakes

| 误区 | 正确做法 |
|------|----------|
| 在已有项目目录内运行脚本 | 切换到父目录；脚本会新建子目录 |
| 非交互环境（CI/容器）调用不传样式参数 | 必须传 `$2 = unocss\|tailwind`，否则交互选择会失败退出 |
| 使用 `npm` / `yarn` 预期兼容 | 脚本硬编码 `pnpm create vue@latest`，请先 `npm i -g pnpm` |
| 担心覆盖 `create-vue` 生成的 `vite.config.ts` | 这是预期行为：脚本会重写 `vite.config.ts` 以注入样式插件与 `@` 别名 |
| 认为脚本会提交 git | 脚本只生成文件，不做 `git init` 额外操作（`create-vue` 自身可能已初始化） |

## Decision: Tailwind vs UnoCSS

- **Tailwind**：生态最成熟，文档丰富，团队熟悉度通常更高，默认配置更贴近主流社区
- **UnoCSS**：原子 CSS，支持 presetAttributify（`bg-red-500` 可写成属性 `bg="red-500"`），打包更小，IDE 插件生态略弱

用户没有偏好时，推荐 **Tailwind CSS**（脚本默认高亮选项）。若明确追求更小打包或原子属性化写法，再选 UnoCSS。

## Reference

- 脚本源码：`install.sh`（位于本仓库根目录）
- 仓库：https://github.com/liasica/vue-starter
- `create-vue` 官方文档：https://github.com/vuejs/create-vue
