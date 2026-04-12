# Pawtopia

> HarmonyOS ArkTS 客户端 + Spring Boot 后端的宠物社区、领养、档案、商城一体化平台。

更新时间：2026-04-12  
适用范围：HarmonyOS 客户端、Spring Boot 后端、内嵌 Web 管理后台

---

## 目录
- [1. 项目简介](#1-项目简介)
- [2. 系统组成](#2-系统组成)
- [3. 技术栈](#3-技术栈)
- [4. 角色与权限](#4-角色与权限)
- [5. 功能总览](#5-功能总览)
- [6. 客户端使用说明](#6-客户端使用说明)
- [7. Web 管理后台使用说明](#7-web-管理后台使用说明)
- [8. 后端接口总览](#8-后端接口总览)
- [9. 媒体资源与图片存储](#9-媒体资源与图片存储)
- [10. 数据库与核心数据模型](#10-数据库与核心数据模型)
- [11. 部署与启动](#11-部署与启动)
- [12. 开发联调与验收建议](#12-开发联调与验收建议)
- [13. 已知说明](#13-已知说明)

---

## 1. 项目简介
Pawtopia 是一个面向宠物生活场景的综合平台，覆盖：
- 社区内容发布与互动
- 宠物领养与申请流转
- 宠物档案与健康记录
- 宠物商城、购物车与订单
- 管理员后台管理商品、宠物、领养与媒体资源

项目由两部分组成：
- `entry/`：HarmonyOS ArkTS 客户端
- `PawtopiaBackend/`：Spring Boot 后端与内嵌 Web 管理后台

---

## 2. 系统组成
### 2.1 Harmony 客户端
提供普通用户、卖家、宠物店、宠物医院、管理员在移动端的业务入口。

### 2.2 Spring Boot 后端
负责：
- 用户鉴权与 JWT
- 商品、宠物、帖子、订单、领养、健康记录等业务 API
- 媒体资源上传与远程抓取
- 后台管理 API
- 内嵌网页管理后台

### 2.3 Web 管理后台
入口：`http://localhost:8080/admin`  
用途：
- 商品管理
- 宠物档案管理
- 领养申请管理
- 媒体资源上传与远程抓取

---

## 3. 技术栈
- **客户端**：HarmonyOS ArkTS + ArkUI
- **后端**：Spring Boot 3.x + Spring Security + JWT
- **数据库**：MySQL 8.x / H2（开发测试）
- **构建**：Maven、hvigor
- **管理后台**：Spring Boot 内嵌静态页面（`static/admin`）

---

## 4. 角色与权限
### 4.1 系统角色
- `USER`：普通用户
- `ADMIN`：管理员
- `PET_SHOP`：宠物店
- `PET_HOSPITAL`：宠物医院
- `SELLER`：卖家

### 4.2 权限原则
- 大部分公开读取接口允许匿名访问
- 写操作默认需要 `Authorization: Bearer <JWT>`
- 后台管理接口默认要求管理员权限
- 卖家只能管理自己的商品
- 宠物主人只能管理自己的宠物与领养申请视图

### 4.3 默认管理员
开发种子数据默认提供管理员：
- 用户名：`user1`
- 密码：`user1`

生产环境请务必修改或关闭默认种子账号。

---

## 5. 功能总览
### 5.1 用户侧功能
- 登录 / 注册
- 社区发帖、点赞、评论
- 浏览领养宠物、提交领养申请、撤回申请
- 新建宠物档案、查看宠物详情、查看健康记录
- 浏览商品、加入购物车、下单、查看订单

### 5.2 管理侧功能
- 管理商品信息
- 管理宠物档案与领养信息
- 审核和更新领养申请状态
- 上传图片、抓取远程图片、统一管理媒体资源

### 5.3 图片资产能力
业务图片不再依赖客户端内置资源：
- 商品图支持后端 URL
- 宠物图支持后端 URL
- 媒体后台支持本地上传和远程抓取
- 客户端优先显示后端图片 URL，旧资源名仍兼容兜底

---

## 6. 客户端使用说明

### 6.1 底部导航
客户端底部包含 5 个主入口：
- 社区
- 领养
- 档案
- 商城
- 我的

### 6.2 登录与注册
#### 登录
- 输入用户名和密码
- 支持配置服务地址
- 登录成功后进入主界面

#### 注册
- 输入用户名、昵称、邮箱、密码、确认密码
- 成功后自动进入系统

### 6.3 社区模块
功能：
- 浏览帖子流
- 搜索帖子
- 切换分类
- 查看帖子详情
- 点赞、评论、回复
- 发布帖子
- 编辑 / 删除自己的帖子

使用流程：
1. 进入社区页
2. 输入关键词搜索或切换分类
3. 点开帖子查看详情
4. 在“我的帖子”里管理自己的内容

### 6.4 领养模块
功能：
- 浏览可领养宠物
- 搜索城市 / 品种 / 宠物名
- 查看我发布的宠物
- 查看我申请的领养
- 查看收到的申请
- 提交申请

使用流程：
1. 进入领养页查看宠物
2. 打开宠物详情
3. 填写联系人、电话、申请说明
4. 提交后在“我的领养申请”查看状态

### 6.5 宠物档案模块
功能：
- 新建宠物
- 编辑宠物基础信息
- 上传 / 填写图片 URL
- 查看宠物详情
- 查看健康档案
- 医院授权

使用流程：
1. 在档案页点击新增宠物
2. 填写宠物信息和图片
3. 保存后在列表和详情中查看

### 6.6 商城模块
功能：
- 浏览商品列表
- 搜索商品
- 分类筛选
- 查看商品详情
- 加入购物车
- 下单

当前分类：
- 全部
- 主粮零食
- 玩具互动
- 宠物服饰
- 护理用品
- 健康护理

### 6.7 我的页面
功能：
- 资料设置
- 我的发布
- 订单中心
- 领养申请
- 角色工作台
- 清理购物车缓存
- 退出登录

### 6.8 管理员在客户端可见入口
管理员在“我的”页可以看到：
- 用户管理
- 内容巡检
- 商品管理
- 宠物档案管理
- 领养信息管理
- 系统订单

说明：客户端管理页适合轻量查看与维护；完整后台管理建议使用 Web 管理后台。

---

## 7. Web 管理后台使用说明

### 7.1 为什么访问 `localhost` 会 403
如果你之前直接访问 `http://localhost:8080/` 出现：
- `HTTP ERROR 403`
- `您未获授权，无法查看此网页`

原因通常是：
- 根路径 `/` 没有放行或没有转发到后台页面

当前版本已修复：
- `GET /` 已允许匿名访问
- `GET /` 会转发到 `/admin/index.html`
- `GET /admin` 同样可直接进入后台页面

建议直接访问：
- `http://localhost:8080/`
- 或 `http://localhost:8080/admin`

### 7.2 后台登录
后台页面本身是静态管理界面，真正的权限依赖后台 API 的 JWT：
1. 打开 `/admin`
2. 在页面中输入管理员账号
3. 点击“管理员登录”
4. 登录成功后，Token 会自动写入
5. 页面可直接操作后台 API

### 7.3 后台菜单
左侧菜单包含：
- 概览
- 商品管理
- 宠物管理
- 领养管理
- 媒体资源

### 7.4 商品管理
支持：
- 查看商品列表
- 查看商品图片
- 新建商品
- 编辑商品
- 删除商品
- 修改价格、库存、分类、卖家 ID、图片 URL

### 7.5 宠物管理
支持：
- 查看宠物列表
- 新建宠物
- 编辑宠物基础档案
- 修改领养城市、领养说明、领养状态
- 删除宠物
- 维护宠物图片 URL

### 7.6 领养管理
支持：
- 查看全部领养申请
- 查看按宠物聚合的申请
- 审批申请状态
- 更新为 `APPROVED` 或 `REJECTED`

### 7.7 媒体资源
支持两种方式：
- 本地上传图片文件
- 输入远程图片 URL，由后端抓取保存

上传成功后：
- 后台返回 `/uploads/...` URL
- 可直接填到商品或宠物的图片字段中
- 客户端会直接读取并展示

---

## 8. 后端接口总览
> 除明确匿名接口外，其余接口都需要 JWT。

### 8.1 鉴权
- `POST /api/auth/login`
- `POST /api/auth/register`

### 8.2 用户
- `GET /api/users`
- `GET /api/users/{id}`
- `POST /api/users`
- `PUT /api/users/{id}`
- `DELETE /api/users/{id}`

### 8.3 宠物
- `GET /api/pets`
- `GET /api/pets/{id}`
- `GET /api/pets/owner/{ownerId}`
- `POST /api/pets`
- `PUT /api/pets/{id}`
- `DELETE /api/pets/{id}`

### 8.4 领养
- `GET /api/adoptions/listings`
- `POST /api/adoptions/pets/{petId}/requests`
- `GET /api/adoptions/pets/{petId}/requests`
- `GET /api/adoptions/requests/mine`
- `PUT /api/adoptions/requests/{id}/status/{status}`
- `PUT /api/adoptions/requests/{id}/cancel`

### 8.5 社区
- `GET /api/posts`
- `GET /api/posts/{id}`
- `POST /api/posts`
- `PUT /api/posts/{id}`
- `DELETE /api/posts/{id}`
- `POST /api/posts/{id}/like`

### 8.6 评论
- `GET /api/comments/post/{postId}`
- `POST /api/comments`
- `PUT /api/comments/{id}`
- `DELETE /api/comments/{id}`

### 8.7 商品与商城
- `GET /api/products`
- `GET /api/products/{id}`
- `GET /api/products/category/{category}`
- `GET /api/products/search?name=...`
- `POST /api/products`
- `PUT /api/products/{id}`
- `DELETE /api/products/{id}`

### 8.8 订单
- `GET /api/orders/user/{userId}`
- `GET /api/orders/{id}`
- `POST /api/orders`
- `PUT /api/orders/{id}`
- `PATCH /api/orders/{id}/status/{status}`
- `DELETE /api/orders/{id}`

### 8.9 健康记录
- `GET /api/health-records/pet/{petId}`
- `POST /api/health-records`
- `PUT /api/health-records/{id}`
- `DELETE /api/health-records/{id}`

### 8.10 后台管理接口
#### 商品管理
- `GET /api/admin/products`
- `GET /api/admin/products/{id}`
- `POST /api/admin/products`
- `PUT /api/admin/products/{id}`
- `DELETE /api/admin/products/{id}`

#### 宠物管理
- `GET /api/admin/pets`
- `GET /api/admin/pets/{id}`
- `POST /api/admin/pets`
- `PUT /api/admin/pets/{id}`
- `DELETE /api/admin/pets/{id}`

#### 领养管理
- `GET /api/admin/adoptions/requests`
- `GET /api/admin/adoptions/requests/{id}`
- `GET /api/admin/adoptions/pets/{petId}/requests`
- `PUT /api/admin/adoptions/requests/{id}/status/{status}`

#### 媒体资源
- `GET /api/admin/media-assets`
- `GET /api/admin/media-assets/{id}`
- `POST /api/admin/media-assets/upload`
- `POST /api/admin/media-assets/fetch`

---

## 9. 媒体资源与图片存储
### 9.1 存储原则
业务图片不再依赖客户端内置资源键：
- 商品图、宠物图、帖子图应优先使用后端 URL
- 头图、宣传图、应用图标仍可保留客户端静态资源

### 9.2 默认存储配置
- 默认上传目录：`uploads`
- 默认公开访问前缀：`/uploads`
- 默认访问形式：`http://localhost:8080/uploads/xxx.jpg`

### 9.3 支持方式
- 本地图片上传
- 远程图片抓取保存
- 客户端填 URL 后直接显示
- 旧资源名仍兼容兜底

### 9.4 客户端同步策略
- 后台保存后立即落库
- 客户端重新进入页面或触发刷新后会读取数据库最新数据
- 当前阶段通过“重新拉取接口”实现同步，不依赖 WebSocket

---

## 10. 数据库与核心数据模型
### 10.1 主要表
- `users`
- `pets`
- `adoption_requests`
- `posts`
- `comments`
- `products`
- `orders`
- `health_records`
- `activities`
- `pet_diaries`
- `media_assets`

### 10.2 关键字段
#### users
- `id`
- `username`
- `password`
- `email`
- `nickname`
- `avatar`
- `phone`
- `role`

#### pets
- `id`
- `name`
- `species`
- `breed`
- `age`
- `gender`
- `description`
- `image`
- `adoptionStatus`
- `adoptionCity`
- `adoptionNote`
- `ownerId`

#### products
- `id`
- `name`
- `description`
- `price`
- `image`
- `stockQuantity`
- `sellerId`
- `category`

#### adoption_requests
- `id`
- `petId`
- `ownerId`
- `requesterId`
- `status`
- `message`
- `contactName`
- `contactPhone`

#### media_assets
- `id`
- `name`
- `originalName`
- `url`
- `contentType`
- `size`
- `createdAt`

---

## 11. 部署与启动
### 11.1 环境准备
- JDK 17
- Maven 3.9+
- MySQL 8.x
- DevEco Studio
- Harmony 构建链（hvigor）

### 11.2 数据库初始化
```sql
CREATE DATABASE pawtopia DEFAULT CHARACTER SET utf8mb4;
```

修改：
- `PawtopiaBackend/src/main/resources/application.properties`
- 数据库地址、用户名、密码

如果不需要种子数据：
- `app.seed.enabled=false`

### 11.3 启动后端
在 `PawtopiaBackend` 目录执行：
```bash
mvn spring-boot:run
```
或：
```bash
mvnw.cmd spring-boot:run
```

默认端口：
- `http://localhost:8080`

### 11.4 启动客户端
1. 用 DevEco Studio 打开项目根目录
2. 根据需要修改客户端服务地址
3. 运行到模拟器或真机

### 11.5 管理后台启动方式
后端启动后，直接访问：
- `http://localhost:8080/`
- 或 `http://localhost:8080/admin`

### 11.6 本地上传目录
如果使用默认配置，运行后端后会自动使用：
- `PawtopiaBackend/uploads`

生产环境建议改到独立目录，并通过环境变量指定。

---

## 12. 开发联调与验收建议
### 12.1 推荐联调顺序
1. 登录获取管理员 JWT
2. 访问 `/admin`
3. 上传一张媒体图片
4. 新建商品并引用图片 URL
5. 新建宠物并引用图片 URL
6. 在客户端验证商品和宠物是否显示新图
7. 提交领养申请并在后台审核
8. 验证客户端页面刷新后状态是否同步

### 12.2 推荐测试命令
后端编译：
```bash
PawtopiaBackend\mvnw.cmd -f PawtopiaBackend\pom.xml -DskipTests compile
```

管理后台测试：
```bash
PawtopiaBackend\mvnw.cmd -f PawtopiaBackend\pom.xml -Dtest=AdminManagementIntegrationTest test
```

关键业务测试：
```bash
PawtopiaBackend\mvnw.cmd -f PawtopiaBackend\pom.xml -Dtest=PostProductOrderIntegrationTest,PetAdoptionHealthIntegrationTest test
```

Harmony 构建：
```bash
"D:\ProgramData\DevEco Studio\tools\node\node.exe" "D:\ProgramData\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon
```

### 12.3 已验证闭环
- 商品 CRUD
- 宠物 CRUD
- 领养申请与审批流转
- 订单状态与库存回补
- 媒体上传后 URL 可访问
- 后台管理接口可用

---

## 13. 已知说明
- 当前客户端仍保留旧资源名兼容逻辑，便于旧数据过渡
- 生产环境请不要使用默认管理员口令
- 后端默认 `ddl-auto=update` 适合开发，不建议生产直接使用
- 当前同步策略以“重新拉接口”为主，不是 WebSocket 推送
- 如果仍看到旧图片或旧商品，通常是旧数据库数据未清理，需要重置种子数据或手动修改记录
- 客户端管理页适合轻量操作，完整管理建议优先使用 `/admin`
