-- Pawtopia demo seed data (manual init)
-- Note:
-- 1) 若你使用后端启动的自动灌入（app.seed.enabled=true），可不执行本文件。
-- 2) password 字段为 BCrypt 哈希（可直接用于登录测试）。

INSERT INTO users (id, username, password, email, nickname, role, created_at, updated_at)
VALUES
  (1, 'user1', '$2a$10$6f5uIhZzZsc5ALviNDomweUdWqBMW/CgYDCNbK4cv1d.mcDw6brze', 'user1@pawtopia.local', '管理员', 'ADMIN', NOW(), NOW()),
  (2, 'shop1', '$2a$10$9C.zylLyqSYnMZy7gxpqReNHTGmY0RI4j9.HLABr0xnURDWA5cjyu', 'shop1@pawtopia.local', '宠物店-示例', 'PET_SHOP', NOW(), NOW()),
  (3, 'hospital1', '$2a$10$WuA93e0pLsnsQYi.Nu/0e.6ZMjb/JG1mRRcxgTR3zT5brYDUiLMaG', 'hospital1@pawtopia.local', '宠物医院-示例', 'PET_HOSPITAL', NOW(), NOW()),
  (4, 'seller1', '$2a$10$X0wPX3Pa2xnPBAVPiWAMieN45j0N4zUlzujNkMKmXRUUGv9Zcz7kK', 'seller1@pawtopia.local', '卖家-示例', 'SELLER', NOW(), NOW());

INSERT INTO products (name, description, price, image, stock_quantity, category, created_at, updated_at)
VALUES
  ('猫粮-示例', '用于演示的猫粮', 39.90, 'https://example.com/product/catfood.png', 200, 'FOOD', NOW(), NOW()),
  ('狗玩具-示例', '用于演示的玩具', 19.90, 'https://example.com/product/toy.png', 300, 'TOY', NOW(), NOW()),
  ('宠物梳子-示例', '用于演示的配件', 12.50, 'https://example.com/product/comb.png', 150, 'ACCESSORY', NOW(), NOW());
