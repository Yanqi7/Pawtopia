# Pawtopia

> HarmonyOS ArkTS 客户端 + Spring Boot 后端 + Spring Boot 内嵌管理后台 的宠物社区 / 领养 / 档案 / 商城综合平台。

更新时间：2026-04-12  
当前主线：业务图片统一迁移到后端 `uploads/`，客户端与后台均读取后端 URL。

---

## 1. 项目概览
Pawtopia 是一个面向宠物场景的综合平台，覆盖：
- 社区内容
- 宠物领养
- 宠物档案与健康记录
- 宠物商城
- 管理后台

当前项目由三部分组成：
- **HarmonyOS 客户端**：用户使用的移动端应用
- **Spring Boot 后端**：统一业务 API、鉴权、数据库、文件存储
- **Spring Boot 内嵌管理后台**：传统管理界面风格网页后台

本项目当前已经明确采用以下资源策略：
- **宣传图 / 头图 / Tab 图标**：继续使用客户端内置 `app.media`
- **商品图 / 宠物图 / 帖子图等业务图片**：统一使用后端 `uploads/` 文件目录 + 数据库存储 URL/路径信息

---

## 2. 系统组成

### 2.1 Harmony 客户端
目录：`entry/src/main/ets/`

主要职责：
- 用户登录注册
- 浏览商品、宠物、帖子
- 提交订单、领养申请
- 创建宠物档案
- 展示后端最新业务数据

### 2.2 Spring Boot 后端
目录：`PawtopiaBackend/`

主要职责：
- 用户认证与 JWT
- 商品、宠物、帖子、订单、领养、健康记录 API
- 管理接口 `/api/admin/**`
- 文件上传与远程图片抓取
- 静态资源访问 `/uploads/**`

### 2.3 内嵌管理后台
目录：`PawtopiaBackend/src/main/resources/static/admin/`

主要职责：
- 商品管理
- 宠物档案管理
- 领养信息管理
- 媒体图片上传与抓取

访问地址：
- `http://localhost:8080/`
- `http://localhost:8080/admin`

---

## 3. 技术栈
- **客户端**：HarmonyOS ArkTS + ArkUI
- **后端**：Spring Boot 3.x + Spring Security + JWT + JPA
- **数据库**：H2 / MySQL
- **构建**：Maven / hvigor
- **媒体存储**：本地文件目录 `uploads/`

---

## 4. 角色与权限
系统角色：
- `USER`：普通用户
- `ADMIN`：管理员
- `PET_SHOP`：宠物店
- `PET_HOSPITAL`：宠物医院
- `SELLER`：商品卖家

权限原则：
- 公共浏览接口允许匿名访问
- 写操作与管理接口需要 JWT
- 管理后台接口统一走 `/api/admin/**`，要求管理员权限

默认管理员账号：
- 用户名：`user1`
- 密码：`user1`

说明：
- 该账号仅用于当前开发/演示环境
- 实际部署必须修改密码并替换 JWT Secret

---

## 5. 客户端使用说明

### 5.1 主导航
底部 5 个入口：
- 社区
- 领养
- 档案
- 商城
- 我的

### 5.2 社区
可执行操作：
- 浏览帖子
- 搜索帖子
- 查看详情
- 评论 / 点赞
- 发布帖子
- 编辑 / 删除自己的帖子

帖子图片说明：
- 业务图片优先来自后端 URL
- 旧资源 key 仅兼容兜底，不建议继续使用

### 5.3 领养
可执行操作：
- 浏览领养宠物
- 查看宠物详情
- 提交领养申请
- 查看我申请的领养
- 查看我收到的申请

### 5.4 档案
可执行操作：
- 新建宠物档案
- 查看宠物详情
- 查看健康记录
- 进行医院授权

宠物图片说明：
- 新建宠物时支持填写后端图片 URL
- 宠物详情与列表页优先读取后端 URL

### 5.5 商城
可执行操作：
- 浏览商品
- 搜索商品
- 查看详情
- 加入购物车
- 提交订单

商品图片说明：
- 商品图应来自后端 `uploads/` 或后端记录的远程 URL
- 不再推荐继续使用客户端本地资源名作为商品图片来源

### 5.6 我的
可执行操作：
- 查看资料
- 进入资料设置
- 查看订单
- 查看领养申请
- 退出登录

管理员额外可见：
- 用户管理
- 内容巡检
- 商品管理
- 宠物档案管理
- 领养信息管理
- 系统订单

---

## 6. 管理后台使用说明

### 6.1 后台入口
启动后端后访问：
- `http://localhost:8080/`
- `http://localhost:8080/admin`

如果访问根路径出现 403：
- 请确认你使用的是最新代码版本
- 最新代码已将 `/`、`/admin`、`/admin/` 转发到后台首页

### 6.2 登录方式
后台接口使用同一套 JWT 鉴权。
推荐流程：
1. 使用管理员账号在客户端或 API 登录
2. 获取 token
3. 管理后台页面调用 `/api/admin/**`

### 6.3 管理能力
当前后台支持：
- 商品列表 / 新增 / 编辑 / 删除
- 宠物列表 / 新增 / 编辑 / 删除
- 领养申请列表 / 详情 / 状态更新
- 媒体上传 / 远程抓取

### 6.4 图片与媒体管理
推荐做法：
- 先通过媒体接口上传文件，获得 `/uploads/...` URL
- 再把该 URL 填入商品 / 宠物 / 帖子图片字段

支持两种方式：
- 本地上传文件
- 输入远程图片 URL，由后端抓取并保存到 `uploads/`

---

## 7. 后端接口清单

### 7.1 鉴权
- `POST /api/auth/login`
- `POST /api/auth/register`

### 7.2 商品
- `GET /api/products`
- `GET /api/products/{id}`
- `POST /api/products`
- `PUT /api/products/{id}`
- `DELETE /api/products/{id}`

### 7.3 宠物
- `GET /api/pets`
- `GET /api/pets/{id}`
- `GET /api/pets/owner/{ownerId}`
- `POST /api/pets`
- `PUT /api/pets/{id}`
- `DELETE /api/pets/{id}`

### 7.4 领养
- `GET /api/adoptions/listings`
- `POST /api/adoptions/pets/{petId}/requests`
- `GET /api/adoptions/pets/{petId}/requests`
- `GET /api/adoptions/requests/mine`
- `GET /api/adoptions/requests/owned`
- `PUT /api/adoptions/requests/{id}/status/{status}`
- `PUT /api/adoptions/requests/{id}/cancel`

### 7.5 订单
- `GET /api/orders/user/{userId}`
- `GET /api/orders/{id}`
- `POST /api/orders`
- `PUT /api/orders/{id}`
- `PUT /api/orders/{id}/status/{status}`
- `PATCH /api/orders/{id}/status/{status}`
- `DELETE /api/orders/{id}`

### 7.6 管理后台接口
- `GET /api/admin/products`
- `GET /api/admin/products/{id}`
- `POST /api/admin/products`
- `PUT /api/admin/products/{id}`
- `DELETE /api/admin/products/{id}`

- `GET /api/admin/pets`
- `GET /api/admin/pets/{id}`
- `POST /api/admin/pets`
- `PUT /api/admin/pets/{id}`
- `DELETE /api/admin/pets/{id}`

- `GET /api/admin/adoptions/requests`
- `GET /api/admin/adoptions/requests/{id}`
- `GET /api/admin/adoptions/pets/{petId}/requests`
- `PUT /api/admin/adoptions/requests/{id}/status/{status}`

- `GET /api/admin/media-assets`
- `GET /api/admin/media-assets/{id}`
- `POST /api/admin/media-assets/upload`
- `POST /api/admin/media-assets/fetch`

- `DELETE /api/admin/content`
  - 管理员一键清空平台全部业务内容
  - 会清空：商品、宠物、帖子、评论、订单、领养申请、健康记录、活动、日记、媒体记录
  - 不删除用户账号本身

### 7.7 静态上传资源
- `GET /uploads/{filename}`

---

## 8. 图片与媒体存储说明

### 8.1 正确的业务图片存储方式
当前项目已明确：
- **不要把业务图片继续绑定到 Harmony 客户端 `media` 资源里**
- **不要把图片二进制直接塞数据库字段里**

正确方式是：
1. 图片文件存后端 `uploads/`
2. 数据库保存 URL 或路径字段
3. 客户端与后台统一读取该 URL

### 8.2 当前目录
后端上传目录：
- `PawtopiaBackend/uploads/`

访问路径：
- `/uploads/**`

配置项：
- `app.storage.upload-dir`
- `app.storage.public-base-path`

### 8.3 客户端图片读取规则
当前客户端规则：
- 先识别 `http/https` URL
- 支持逗号分隔多图
- 旧资源 key 仍兼容兜底

但实际运营建议：
- 后续业务图全部统一使用后端 URL
- 旧资源 key 只保留兼容，不再继续录入新内容

---

## 9. 数据库与内容清理说明

### 9.1 数据库存储的是什么
当前数据库里的图片字段通常存的是：
- 图片 URL
- 或旧资源 key 字符串

不是直接存图片文件二进制。

### 9.2 为什么你会看到很多占位内容
原因通常有三类：
- 旧 seed 示例数据仍在数据库里
- 某些图片字段还是旧资源 key
- 离线 MockData 在后端不可用时补了示例数据

### 9.3 当前建议
如果你要后续全部人工手动录入内容，建议：
1. 关闭自动 seed
2. 清空平台现有业务内容
3. 保留账号体系
4. 后续所有图片全部通过后台上传或远程抓取进入 `uploads/`

### 9.4 清空平台内容
最新版后端提供：
- `DELETE /api/admin/content`

作用：
- 清空全部业务内容
- 保留用户账号
- 适合你现在“删掉平台全部内容，后续人工录入”的目标

说明：
- 上传目录里的旧文件建议一并人工清理或由后台扩展文件清理能力
- 当前接口删除数据库中的媒体记录，但是否删除磁盘文件取决于运行时清理策略

---

## 10. 从 0 启动项目

### 10.1 启动后端
在 `PawtopiaBackend` 目录：

```bash
mvn spring-boot:run
```

或 Windows：

```bash
mvnw.cmd spring-boot:run
```

默认端口：
- `http://localhost:8080`

### 10.2 启动客户端
1. 用 DevEco Studio 打开项目
2. 确认客户端服务地址指向后端
3. 使用 hvigor / DevEco 运行到模拟器或真机

### 10.3 访问后台
- `http://localhost:8080/admin`

---

## 11. 清空旧内容并切到人工录入模式

这是你当前最需要的流程。

### 第一步：关闭自动示例灌数
当前默认配置已建议关闭：
- `app.seed.enabled=false`
- `app.seed.on-h2=false`

### 第二步：启动后端
确保后端可访问：
- `http://localhost:8080`

### 第三步：管理员登录
管理员账号：
- `user1 / user1`

### 第四步：执行清空
调用：

```http
DELETE /api/admin/content
Authorization: Bearer <token>
```

### 第五步：清理 uploads 历史文件
如果你要彻底从零开始，建议把：
- `PawtopiaBackend/uploads/`
中的旧文件也清空。

### 第六步：人工录入内容
后续通过：
- 管理后台上传媒体
- 管理后台创建商品 / 宠物 / 领养内容
- 客户端重新拉取最新接口数据

---

## 12. 验收建议

建议至少验证以下闭环：
- 上传图片 → 返回 `/uploads/...` → 前端页面正确显示
- 新建商品 → 商城列表显示真实图
- 新建宠物 → 档案 / 领养列表显示真实图
- 修改领养状态 → 客户端重进页面可见最新结果
- 删除旧内容后 → 列表为空，不再出现旧假数据

---

## 13. 已知说明
- 旧的客户端本地资源 key 仍有兼容逻辑，但不建议继续作为业务图来源
- 真实 HTTP 冒烟与全量运行效果，仍以你本机当前运行的后端/客户端为准
- 如果你希望完全不依赖任何旧资源名，我下一步可以继续把兼容兜底逻辑也删掉，只保留 URL 模式

---

## 14. 下一步建议
如果你要把平台彻底切成“纯人工运营录入”，下一步建议我继续做：
- 删除前端对旧资源 key 的兼容兜底
- 后台增加“清空 uploads 文件夹”按钮
- 后台增加媒体库页面的缩略图预览、搜索与删除
- 移除默认管理员弱口令与默认 JWT Secret
