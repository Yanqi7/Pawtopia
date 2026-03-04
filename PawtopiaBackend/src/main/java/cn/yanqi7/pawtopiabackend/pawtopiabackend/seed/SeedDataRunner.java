package cn.yanqi7.pawtopiabackend.pawtopiabackend.seed;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Comment;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.HealthRecord;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Order;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Pet;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Post;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Product;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.User;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.CommentRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.HealthRecordRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.OrderRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.PetRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.PostRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.ProductRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

@Component
public class SeedDataRunner implements CommandLineRunner {
    private static final String ADMIN_USERNAME = "user1";
    private static final String ADMIN_PASSWORD = "user1";

    private final UserRepository userRepository;
    private final ProductRepository productRepository;
    private final PetRepository petRepository;
    private final PostRepository postRepository;
    private final CommentRepository commentRepository;
    private final HealthRecordRepository healthRecordRepository;
    private final OrderRepository orderRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.seed.enabled:true}")
    private boolean seedEnabled;

    public SeedDataRunner(
            UserRepository userRepository,
            ProductRepository productRepository,
            PetRepository petRepository,
            PostRepository postRepository,
            CommentRepository commentRepository,
            HealthRecordRepository healthRecordRepository,
            OrderRepository orderRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
        this.productRepository = productRepository;
        this.petRepository = petRepository;
        this.postRepository = postRepository;
        this.commentRepository = commentRepository;
        this.healthRecordRepository = healthRecordRepository;
        this.orderRepository = orderRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        User admin = ensureUser(ADMIN_USERNAME, ADMIN_PASSWORD, "user1@pawtopia.local", "管理员", User.Role.ADMIN);
        if (!seedEnabled) {
            return;
        }

        List<User> seedUsers = new ArrayList<>();
        seedUsers.add(admin);
        seedUsers.add(ensureUser("shop1", "shop1", "shop1@pawtopia.local", "宠物店-示例", User.Role.PET_SHOP));
        seedUsers.add(ensureUser("hospital1", "hospital1", "hospital1@pawtopia.local", "宠物医院-示例", User.Role.PET_HOSPITAL));
        seedUsers.add(ensureUser("seller1", "seller1", "seller1@pawtopia.local", "卖家-示例", User.Role.SELLER));
        for (int i = 2; i <= 12; i++) {
            seedUsers.add(ensureUser("user" + i, "user" + i, "user" + i + "@pawtopia.local", "用户" + i, User.Role.USER));
        }

        Random random = new Random(20260227L);

        List<Product> products = seedProducts(random, 80);
        List<Pet> pets = seedPets(random, seedUsers, 40);
        List<Post> posts = seedPosts(random, seedUsers, pets, 60);
        seedComments(random, seedUsers, posts, 180);
        seedHealthRecords(random, pets, 100);
        seedOrders(random, seedUsers, products, 40);
    }

    private User ensureUser(String username, String rawPassword, String email, String nickname, User.Role role) {
        return userRepository.findByUsername(username).map(existing -> {
            boolean dirty = false;
            if (existing.getRole() == null || existing.getRole() != role) {
                existing.setRole(role);
                dirty = true;
            }
            if (existing.getEmail() == null || existing.getEmail().isBlank()) {
                existing.setEmail(email);
                dirty = true;
            }
            if (existing.getNickname() == null || existing.getNickname().isBlank()) {
                existing.setNickname(nickname);
                dirty = true;
            }
            if (existing.getPassword() == null || existing.getPassword().isBlank()
                    || !passwordEncoder.matches(rawPassword, existing.getPassword())) {
                existing.setPassword(passwordEncoder.encode(rawPassword));
                dirty = true;
            }
            return dirty ? userRepository.save(existing) : existing;
        }).orElseGet(() -> {
            User user = new User();
            user.setUsername(username);
            user.setPassword(passwordEncoder.encode(rawPassword));
            user.setEmail(email);
            user.setNickname(nickname);
            user.setRole(role);
            return userRepository.save(user);
        });
    }

    private List<Product> seedProducts(Random random, int desired) {
        long existing = productRepository.count();
        if (existing >= desired) {
            return productRepository.findAll();
        }
        List<Product> created = new ArrayList<>();
        Product.ProductCategory[] categories = Product.ProductCategory.values();
        for (long i = existing + 1; i <= desired; i++) {
            Product p = new Product();
            p.setName("宠物商品-" + i);
            p.setDescription("用于演示的商品详情（自动生成）：" + i);
            p.setImage("https://example.com/product/" + i + ".png");
            p.setCategory(categories[(int) (i % categories.length)]);
            p.setStockQuantity(100 + (int) (i % 300));
            p.setPrice(BigDecimal.valueOf(9.9 + (i % 50) + (random.nextInt(90) / 10.0)));
            created.add(p);
        }
        productRepository.saveAll(created);
        return productRepository.findAll();
    }

    private List<Pet> seedPets(Random random, List<User> users, int desired) {
        long existing = petRepository.count();
        if (existing >= desired) {
            return petRepository.findAll();
        }
        List<Pet> created = new ArrayList<>();
        String[] species = new String[]{"猫", "狗", "兔", "仓鼠"};
        String[] breeds = new String[]{"中华田园", "英短", "金毛", "拉布拉多", "布偶", "泰迪"};
        String[] colors = new String[]{"黑", "白", "橘", "灰", "花"};
        for (long i = existing + 1; i <= desired; i++) {
            User owner = users.get(random.nextInt(users.size()));
            Pet pet = new Pet();
            pet.setName("宠物" + i);
            pet.setSpecies(species[random.nextInt(species.length)]);
            pet.setBreed(breeds[random.nextInt(breeds.length)]);
            pet.setColor(colors[random.nextInt(colors.length)]);
            pet.setAge(1 + random.nextInt(12));
            pet.setGender(random.nextBoolean() ? Pet.Gender.MALE : Pet.Gender.FEMALE);
            pet.setSize(random.nextBoolean() ? "小" : "中");
            pet.setDescription("用于演示的宠物档案（自动生成）：" + i);
            pet.setBirthDate(LocalDate.now().minusYears(1 + random.nextInt(8)).minusDays(random.nextInt(300)));
            pet.setOwnerId(owner.getId());
            pet.setAdoptionStatus(random.nextInt(10) < 7 ? Pet.AdoptionStatus.AVAILABLE : Pet.AdoptionStatus.PAUSED);
            pet.setAdoptionCity(random.nextBoolean() ? "北京" : "上海");
            pet.setAdoptionNote("希望领养人有耐心，愿意定期回访（演示数据）");
            created.add(pet);
        }
        petRepository.saveAll(created);
        return petRepository.findAll();
    }

    private List<Post> seedPosts(Random random, List<User> users, List<Pet> pets, int desired) {
        long existing = postRepository.count();
        if (existing >= desired) {
            return postRepository.findAll();
        }
        List<Post> created = new ArrayList<>();
        for (long i = existing + 1; i <= desired; i++) {
            User author = users.get(random.nextInt(users.size()));
            Post post = new Post();
            post.setTitle("帖子标题-" + i);
            post.setContent("这是用于演示的帖子内容（自动生成）：" + i + "\n\n支持离线占位数据展示与匿名浏览。");
            post.setUserId(author.getId());
            if (!pets.isEmpty() && random.nextBoolean()) {
                post.setPetId(pets.get(random.nextInt(pets.size())).getId());
            }
            post.setImageUrls("https://example.com/post/" + i + "/1.png,https://example.com/post/" + i + "/2.png");
            post.setViewCount(random.nextInt(5000));
            post.setLikeCount(random.nextInt(2000));
            created.add(post);
        }
        postRepository.saveAll(created);
        return postRepository.findAll();
    }

    private void seedComments(Random random, List<User> users, List<Post> posts, int desired) {
        long existing = commentRepository.count();
        if (existing >= desired || posts.isEmpty()) {
            return;
        }
        List<Comment> created = new ArrayList<>();
        for (long i = existing + 1; i <= desired; i++) {
            User author = users.get(random.nextInt(users.size()));
            Post post = posts.get(random.nextInt(posts.size()));
            Comment c = new Comment();
            c.setPostId(post.getId());
            c.setUserId(author.getId());
            c.setParentId(null);
            c.setContent("评论内容（自动生成）：" + i);
            c.setLikeCount(random.nextInt(200));
            created.add(c);
        }
        commentRepository.saveAll(created);
    }

    private void seedHealthRecords(Random random, List<Pet> pets, int desired) {
        long existing = healthRecordRepository.count();
        if (existing >= desired || pets.isEmpty()) {
            return;
        }
        List<HealthRecord> created = new ArrayList<>();
        HealthRecord.RecordType[] types = HealthRecord.RecordType.values();
        for (long i = existing + 1; i <= desired; i++) {
            Pet pet = pets.get(random.nextInt(pets.size()));
            HealthRecord r = new HealthRecord();
            r.setPetId(pet.getId());
            r.setRecordType(types[(int) (i % types.length)]);
            r.setTitle("健康记录-" + i);
            r.setDescription("用于演示的健康记录（自动生成）：" + i);
            r.setRecordDate(LocalDate.now().minusDays(random.nextInt(700)));
            if (random.nextBoolean()) {
                r.setNextDueDate(LocalDate.now().plusDays(10 + random.nextInt(120)));
            }
            r.setVeterinarian(random.nextBoolean() ? "张医生" : "李医生");
            created.add(r);
        }
        healthRecordRepository.saveAll(created);
    }

    private void seedOrders(Random random, List<User> users, List<Product> products, int desired) {
        long existing = orderRepository.count();
        if (existing >= desired || products.isEmpty()) {
            return;
        }
        List<Order> created = new ArrayList<>();
        Order.OrderStatus[] statuses = Order.OrderStatus.values();
        for (long i = existing + 1; i <= desired; i++) {
            User buyer = users.get(random.nextInt(users.size()));

            int itemCount = 1 + random.nextInt(3);
            List<Product> picked = new ArrayList<>();
            List<Integer> quantities = new ArrayList<>();
            for (int j = 0; j < itemCount; j++) {
                picked.add(products.get(random.nextInt(products.size())));
                quantities.add(1 + random.nextInt(2));
            }

            BigDecimal total = BigDecimal.ZERO;
            StringBuilder productIds = new StringBuilder();
            StringBuilder qtyStr = new StringBuilder();
            for (int j = 0; j < picked.size(); j++) {
                Product p = picked.get(j);
                int q = quantities.get(j);
                if (j > 0) {
                    productIds.append(",");
                    qtyStr.append(",");
                }
                productIds.append(p.getId());
                qtyStr.append(q);
                total = total.add(p.getPrice().multiply(BigDecimal.valueOf(q)));
            }

            Order o = new Order();
            o.setUserId(buyer.getId());
            o.setProductIds(productIds.toString());
            o.setQuantities(qtyStr.toString());
            o.setTotalAmount(total);
            o.setStatus(statuses[random.nextInt(statuses.length)]);
            o.setShippingAddress("示例地址-" + (100 + random.nextInt(500)) + "号");
            o.setContactName(buyer.getNickname() == null ? buyer.getUsername() : buyer.getNickname());
            o.setContactPhone("1380000" + String.format("%04d", random.nextInt(10000)));
            created.add(o);
        }
        orderRepository.saveAll(created);
    }
}
