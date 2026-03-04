-- Pawtopia MySQL schema (manual init)
-- Note: JPA 会自动建表/更新；此文件用于数据库无法自动初始化时的手动建表。

CREATE TABLE IF NOT EXISTS users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(64) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  email VARCHAR(128) NOT NULL UNIQUE,
  nickname VARCHAR(128),
  avatar VARCHAR(255),
  age INT,
  gender VARCHAR(32),
  phone VARCHAR(32),
  role VARCHAR(32) NOT NULL DEFAULT 'USER',
  created_at DATETIME,
  updated_at DATETIME
);

CREATE TABLE IF NOT EXISTS products (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  image VARCHAR(255),
  stock_quantity INT NOT NULL,
  category VARCHAR(32) NOT NULL,
  created_at DATETIME,
  updated_at DATETIME
);

CREATE TABLE IF NOT EXISTS pets (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  species VARCHAR(64) NOT NULL,
  breed VARCHAR(64),
  color VARCHAR(64),
  age INT,
  gender VARCHAR(16),
  size VARCHAR(16),
  description TEXT,
  adoption_status VARCHAR(32) NOT NULL DEFAULT 'AVAILABLE',
  adoption_city VARCHAR(64),
  adoption_note VARCHAR(255),
  birth_date DATE,
  owner_id BIGINT NOT NULL,
  created_at DATETIME,
  updated_at DATETIME,
  INDEX idx_pets_owner_id (owner_id)
);

CREATE TABLE IF NOT EXISTS posts (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  user_id BIGINT NOT NULL,
  pet_id BIGINT,
  image_urls VARCHAR(1024),
  view_count INT DEFAULT 0,
  like_count INT DEFAULT 0,
  comment_count INT DEFAULT 0,
  created_at DATETIME,
  updated_at DATETIME,
  INDEX idx_posts_user_id (user_id),
  INDEX idx_posts_pet_id (pet_id)
);

CREATE TABLE IF NOT EXISTS comments (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  post_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  parent_id BIGINT,
  content TEXT NOT NULL,
  like_count INT DEFAULT 0,
  created_at DATETIME,
  updated_at DATETIME,
  INDEX idx_comments_post_id (post_id),
  INDEX idx_comments_user_id (user_id)
);

CREATE TABLE IF NOT EXISTS health_records (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  pet_id BIGINT NOT NULL,
  record_type VARCHAR(32) NOT NULL,
  title VARCHAR(255),
  description TEXT,
  record_date DATE NOT NULL,
  next_due_date DATE,
  veterinarian VARCHAR(128),
  created_at DATETIME,
  updated_at DATETIME,
  INDEX idx_health_records_pet_id (pet_id)
);

CREATE TABLE IF NOT EXISTS orders (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  product_ids VARCHAR(1024) NOT NULL,
  quantities VARCHAR(1024) NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  status VARCHAR(32) NOT NULL,
  shipping_address VARCHAR(255),
  contact_phone VARCHAR(32),
  contact_name VARCHAR(128),
  created_at DATETIME,
  updated_at DATETIME,
  INDEX idx_orders_user_id (user_id)
);

CREATE TABLE IF NOT EXISTS pet_diaries (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  pet_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  image VARCHAR(255),
  diary_date DATE NOT NULL,
  created_at DATETIME,
  updated_at DATETIME,
  INDEX idx_pet_diaries_pet_id (pet_id),
  INDEX idx_pet_diaries_user_id (user_id)
);

CREATE TABLE IF NOT EXISTS activities (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  pet_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  type VARCHAR(32) NOT NULL,
  activity_date DATETIME NOT NULL,
  duration INT,
  calories DOUBLE,
  created_at DATETIME,
  updated_at DATETIME,
  INDEX idx_activities_pet_id (pet_id),
  INDEX idx_activities_user_id (user_id)
);

CREATE TABLE IF NOT EXISTS adoption_requests (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  pet_id BIGINT NOT NULL,
  owner_id BIGINT NOT NULL,
  requester_id BIGINT NOT NULL,
  status VARCHAR(32) NOT NULL,
  message VARCHAR(1024),
  contact_name VARCHAR(128),
  contact_phone VARCHAR(32),
  created_at DATETIME,
  updated_at DATETIME,
  INDEX idx_adoption_requests_pet_id (pet_id),
  INDEX idx_adoption_requests_owner_id (owner_id),
  INDEX idx_adoption_requests_requester_id (requester_id)
);
