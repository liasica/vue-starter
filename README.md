# vue-starter

用于快速初始化 Vue 项目基础配置的脚本集合。

脚本会先创建 Vue 项目，`create-vue` 保持交互式流程；创建成功后自动进入目录继续执行初始化，并交互式选择使用 UnoCSS 或 Tailwind。

## 使用方式

```bash
curl -fsSL https://raw.githubusercontent.com/liasica/vue-starter/master/install.sh | bash
```

## 说明

- 默认直接进入 `create-vue` 交互流程，由它询问项目名和项目特性。
- Vue 项目创建完成后，脚本会继续以接近 `create-vue` 的交互式提示让你选择 `UnoCSS` 或 `Tailwind CSS`。
- 样式菜单支持 `←/→`、`↑/↓`、空格、`h/j/k/l`、`1/2` 和回车确认。
- 如有需要，也可以通过 `bash -s -- my-app` 预先传入项目目录名。
- 如需跳过样式选择交互，也可以通过 `bash -s -- my-app unocss` 或 `bash -s -- my-app tailwind` 直接指定。
