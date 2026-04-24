# vue-starter

用于快速初始化 Vue 项目基础配置的脚本集合。

脚本会先创建 Vue 项目，`create-vue` 保持交互式流程；创建成功后自动进入目录继续执行初始化，并交互式选择使用 Tailwind CSS 或 UnoCSS。

## 使用方式

```bash
curl -fsSL https://raw.githubusercontent.com/liasica/vue-starter/master/install.sh | bash
```

## 说明

- 默认直接进入 `create-vue` 交互流程，由它询问项目名和项目特性。
- Vue 项目创建完成后，脚本会继续以接近 `create-vue` 的交互式提示让你选择 `Tailwind CSS` 或 `UnoCSS`，默认高亮 Tailwind CSS。
- 样式菜单支持 `←/→`、`↑/↓`、空格、`h/j/k/l`、`1/2` 和回车确认。
- 如有需要，也可以通过 `bash -s -- my-app` 预先传入项目目录名。
- 如需跳过样式选择交互，也可以通过 `bash -s -- my-app tailwind` 或 `bash -s -- my-app unocss` 直接指定。

## Claude / Codex Skill

本仓库在 `skills/vue-starter-init/` 下提供了一份 agent skill（遵循 [agentskills.io](https://agentskills.io/specification) 规范），用于让 Claude Code 或 Codex 在用户要求「初始化 Vue3 项目」时自动发现并调用本脚本。

### 安装

将 skill 目录软链接到 agent 的 skills 根目录即可：

```bash
# Codex（~/.agents/skills/）
ln -s "$(pwd)/skills/vue-starter-init" ~/.agents/skills/vue-starter-init

# Claude Code（~/.claude/skills/，若采用软链到 ~/.agents/skills 的组织方式则无需再建）
ln -s ../../.agents/skills/vue-starter-init ~/.claude/skills/vue-starter-init
```

### 触发

安装后，当用户对 Claude 或 Codex 说「新建一个 Vue3 项目」「初始化 vue 工程」「scaffold a vue 3 app」等，agent 会匹配到 `vue-starter-init` 并按 `SKILL.md` 的指引调用：

```bash
curl -fsSL https://raw.githubusercontent.com/liasica/vue-starter/master/install.sh | bash
```
