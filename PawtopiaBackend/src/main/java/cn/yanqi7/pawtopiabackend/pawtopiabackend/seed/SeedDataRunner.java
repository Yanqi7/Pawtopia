package cn.yanqi7.pawtopiabackend.pawtopiabackend.seed;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.AdoptionRequest;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Comment;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.HealthRecord;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Order;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Pet;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Post;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Product;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.User;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.AdoptionRequestRepository;
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
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

@Component
public class SeedDataRunner implements CommandLineRunner {
    private static final String ADMIN_USERNAME = "user1";
    private static final String ADMIN_PASSWORD = "user1";
    private static final String[] CITIES = {"北京", "上海", "杭州", "成都", "深圳", "广州"};

    private final UserRepository userRepository;
    private final ProductRepository productRepository;
    private final PetRepository petRepository;
    private final PostRepository postRepository;
    private final CommentRepository commentRepository;
    private final HealthRecordRepository healthRecordRepository;
    private final OrderRepository orderRepository;
    private final AdoptionRequestRepository adoptionRequestRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.seed.enabled:false}")
    private boolean seedEnabled;

    @Value("${spring.datasource.url:}")
    private String datasourceUrl;

    public SeedDataRunner(
            UserRepository userRepository,
            ProductRepository productRepository,
            PetRepository petRepository,
            PostRepository postRepository,
            CommentRepository commentRepository,
            HealthRecordRepository healthRecordRepository,
            OrderRepository orderRepository,
            AdoptionRequestRepository adoptionRequestRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.userRepository = userRepository;
        this.productRepository = productRepository;
        this.petRepository = petRepository;
        this.postRepository = postRepository;
        this.commentRepository = commentRepository;
        this.healthRecordRepository = healthRecordRepository;
        this.orderRepository = orderRepository;
        this.adoptionRequestRepository = adoptionRequestRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        User admin = ensureUser(ADMIN_USERNAME, ADMIN_PASSWORD, "user1@chengchong.local", "社区管理员", User.Role.ADMIN);
        boolean h2Mode = datasourceUrl != null && datasourceUrl.contains(":h2:");
        if (!h2Mode && !seedEnabled) {
            return;
        }

        List<User> seedUsers = new ArrayList<>();
        seedUsers.add(admin);
        seedUsers.add(ensureUser("shop1", "shop1", "shop1@chengchong.local", "社区宠物门店", User.Role.PET_SHOP));
        seedUsers.add(ensureUser("hospital1", "hospital1", "hospital1@chengchong.local", "贝克宠物医院", User.Role.PET_HOSPITAL));
        seedUsers.add(ensureUser("seller1", "seller1", "seller1@chengchong.local", "安吉宠物用品店", User.Role.SELLER));
        for (int i = 2; i <= 12; i++) {
            seedUsers.add(ensureUser("user" + i, "user" + i, "user" + i + "@chengchong.local", "宠友" + i, User.Role.USER));
        }

        List<Product> products = seedProducts(80);
        List<Pet> pets = seedPets(seedUsers, 40);
        List<Post> posts = seedPosts(seedUsers, pets, 60);
        seedComments(seedUsers, posts, 180);
        seedHealthRecords(pets, 100);
        seedOrders(seedUsers, products, 40);
        seedAdoptionRequests(seedUsers, pets, 36);
    }

    private User ensureUser(String username, String rawPassword, String email, String nickname, User.Role role) {
        return userRepository.findByUsername(username).map(existing -> {
            boolean dirty = false;
            if (existing.getRole() == null || existing.getRole() != role) {
                existing.setRole(role);
                dirty = true;
            }
            if (blank(existing.getEmail())) {
                existing.setEmail(email);
                dirty = true;
            }
            if (blank(existing.getNickname())) {
                existing.setNickname(nickname);
                dirty = true;
            }
            if (blank(existing.getPassword()) || !passwordEncoder.matches(rawPassword, existing.getPassword())) {
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

    private List<Product> seedProducts(int desired) {
        List<Product> all = new ArrayList<>(productRepository.findAll());
        all.sort(Comparator.comparing(Product::getId));
        List<Product> dirty = new ArrayList<>();

        int normalizeCount = Math.min(all.size(), desired);
        for (int i = 0; i < normalizeCount; i++) {
            Product product = all.get(i);
            applyProductTemplate(product, productTemplate(i));
            dirty.add(product);
        }
        for (int i = normalizeCount; i < all.size(); i++) {
            Product product = all.get(i);
            ProductTemplate template = productTemplate(i);
            if (blank(product.getImage())) {
                product.setImage(template.imageKey());
                dirty.add(product);
            }
        }

        while (all.size() < desired) {
            Product product = new Product();
            applyProductTemplate(product, productTemplate(all.size()));
            all.add(product);
            dirty.add(product);
        }

        if (!dirty.isEmpty()) {
            productRepository.saveAll(dirty);
        }
        return new ArrayList<>(productRepository.findAll());
    }

    private List<Pet> seedPets(List<User> users, int desired) {
        List<User> owners = users.stream()
                .filter(user -> user.getRole() == User.Role.USER || user.getRole() == User.Role.PET_SHOP)
                .toList();
        List<Pet> all = new ArrayList<>(petRepository.findAll());
        all.sort(Comparator.comparing(Pet::getId));
        List<Pet> dirty = new ArrayList<>();

        int normalizeCount = Math.min(all.size(), desired);
        for (int i = 0; i < normalizeCount; i++) {
            Pet pet = all.get(i);
            PetTemplate template = petTemplate(i, owners.get(i % owners.size()).getId());
            applyPetTemplate(pet, template, pet.getOwnerId());
            dirty.add(pet);
        }
        for (int i = normalizeCount; i < all.size(); i++) {
            Pet pet = all.get(i);
            if (blank(pet.getImage()) || !isValidBreedForSpecies(pet.getSpecies(), pet.getBreed())) {
                PetTemplate template = petTemplate(i, owners.get(i % owners.size()).getId());
                if (blank(pet.getImage())) {
                    pet.setImage(template.imageKey());
                }
                if (!isValidBreedForSpecies(pet.getSpecies(), pet.getBreed())) {
                    pet.setBreed(template.breed());
                }
                dirty.add(pet);
            }
        }

        while (all.size() < desired) {
            long ownerId = owners.get(all.size() % owners.size()).getId();
            Pet pet = new Pet();
            applyPetTemplate(pet, petTemplate(all.size(), ownerId), ownerId);
            all.add(pet);
            dirty.add(pet);
        }

        if (!dirty.isEmpty()) {
            petRepository.saveAll(dirty);
        }
        return new ArrayList<>(petRepository.findAll());
    }

    private List<Post> seedPosts(List<User> users, List<Pet> pets, int desired) {
        List<Post> all = new ArrayList<>(postRepository.findAll());
        all.sort(Comparator.comparing(Post::getId));
        List<Post> dirty = new ArrayList<>();

        int normalizeCount = Math.min(all.size(), desired);
        for (int i = 0; i < normalizeCount; i++) {
            Post post = all.get(i);
            User author = findUserById(users, post.getUserId(), users.get(i % users.size()));
            Long petId = !pets.isEmpty() ? pets.get(i % pets.size()).getId() : null;
            applyPostTemplate(post, postTemplate(i, author.getRole(), petId), post.getUserId() == null ? author.getId() : post.getUserId());
            dirty.add(post);
        }
        for (int i = normalizeCount; i < all.size(); i++) {
            Post post = all.get(i);
            if (blank(post.getImageUrls())) {
                User author = findUserById(users, post.getUserId(), users.get(i % users.size()));
                Long petId = !pets.isEmpty() ? pets.get(i % pets.size()).getId() : null;
                post.setImageUrls(postTemplate(i, author.getRole(), petId).imageUrls());
                dirty.add(post);
            }
        }

        while (all.size() < desired) {
            User author = users.get(all.size() % users.size());
            Long petId = !pets.isEmpty() ? pets.get(all.size() % pets.size()).getId() : null;
            Post post = new Post();
            applyPostTemplate(post, postTemplate(all.size(), author.getRole(), petId), author.getId());
            all.add(post);
            dirty.add(post);
        }

        if (!dirty.isEmpty()) {
            postRepository.saveAll(dirty);
        }
        return new ArrayList<>(postRepository.findAll());
    }

    private void seedComments(List<User> users, List<Post> posts, int desired) {
        if (posts.isEmpty()) {
            return;
        }
        List<Comment> all = new ArrayList<>(commentRepository.findAll());
        all.sort(Comparator.comparing(Comment::getId));
        List<Comment> dirty = new ArrayList<>();

        int normalizeCount = Math.min(all.size(), desired);
        for (int i = 0; i < normalizeCount; i++) {
            Comment comment = all.get(i);
            CommentTemplate template = commentTemplate(i, posts.get(i % posts.size()));
            comment.setContent(template.content());
            if (comment.getLikeCount() == null || comment.getLikeCount() < 0) {
                comment.setLikeCount(template.likeCount());
            }
            dirty.add(comment);
        }

        while (all.size() < desired) {
            Post post = posts.get(all.size() % posts.size());
            User author = users.get((all.size() + 1) % users.size());
            CommentTemplate template = commentTemplate(all.size(), post);
            Comment comment = new Comment();
            comment.setPostId(post.getId());
            comment.setUserId(author.getId());
            comment.setParentId(null);
            comment.setContent(template.content());
            comment.setLikeCount(template.likeCount());
            all.add(comment);
            dirty.add(comment);
        }

        if (!dirty.isEmpty()) {
            commentRepository.saveAll(dirty);
        }
    }

    private void seedHealthRecords(List<Pet> pets, int desired) {
        if (pets.isEmpty()) {
            return;
        }
        List<HealthRecord> all = new ArrayList<>(healthRecordRepository.findAll());
        all.sort(Comparator.comparing(HealthRecord::getId));
        List<HealthRecord> dirty = new ArrayList<>();

        int normalizeCount = Math.min(all.size(), desired);
        for (int i = 0; i < normalizeCount; i++) {
            HealthRecord record = all.get(i);
            HealthTemplate template = healthTemplate(i, pets.get(i % pets.size()));
            applyHealthTemplate(record, template, record.getPetId() == null ? pets.get(i % pets.size()).getId() : record.getPetId());
            dirty.add(record);
        }

        while (all.size() < desired) {
            Pet pet = pets.get(all.size() % pets.size());
            HealthRecord record = new HealthRecord();
            applyHealthTemplate(record, healthTemplate(all.size(), pet), pet.getId());
            all.add(record);
            dirty.add(record);
        }

        if (!dirty.isEmpty()) {
            healthRecordRepository.saveAll(dirty);
        }
    }

    private void seedOrders(List<User> users, List<Product> products, int desired) {
        if (products.isEmpty()) {
            return;
        }
        List<User> buyers = users.stream().filter(user -> user.getRole() == User.Role.USER).toList();
        List<Order> all = new ArrayList<>(orderRepository.findAll());
        all.sort(Comparator.comparing(Order::getId));
        List<Order> dirty = new ArrayList<>();

        int normalizeCount = Math.min(all.size(), desired);
        for (int i = 0; i < normalizeCount; i++) {
            Order order = all.get(i);
            normalizeOrder(order, buyers.get(i % buyers.size()), products, i);
            dirty.add(order);
        }

        while (all.size() < desired) {
            User buyer = buyers.get(all.size() % buyers.size());
            Order order = new Order();
            normalizeOrder(order, buyer, products, all.size());
            all.add(order);
            dirty.add(order);
        }

        if (!dirty.isEmpty()) {
            orderRepository.saveAll(dirty);
        }
    }

    private void normalizeOrder(Order order, User buyer, List<Product> products, int index) {
        Product first = products.get(index % products.size());
        Product second = products.get((index + 3) % products.size());
        int firstQty = 1 + (index % 2);
        int secondQty = index % 3 == 0 ? 1 : 0;
        BigDecimal total = first.getPrice().multiply(BigDecimal.valueOf(firstQty));
        String productIds = String.valueOf(first.getId());
        String quantities = String.valueOf(firstQty);
        if (secondQty > 0) {
            total = total.add(second.getPrice().multiply(BigDecimal.valueOf(secondQty)));
            productIds = productIds + "," + second.getId();
            quantities = quantities + "," + secondQty;
        }
        order.setUserId(order.getUserId() == null ? buyer.getId() : order.getUserId());
        order.setProductIds(productIds);
        order.setQuantities(quantities);
        order.setTotalAmount(total);
        if (order.getStatus() == null) {
            order.setStatus(index % 4 == 0 ? Order.OrderStatus.SHIPPED : Order.OrderStatus.PAID);
        }
        order.setShippingAddress(cityByIndex(index) + "市朝阳路" + (18 + index) + "号");
        order.setContactName(blank(order.getContactName()) ? safeName(buyer) : order.getContactName());
        order.setContactPhone(blank(order.getContactPhone()) ? "1380000" + String.format(Locale.ROOT, "%04d", index) : order.getContactPhone());
    }

    private String pickVariantName(int variant, String... names) {
        if (names.length == 0) {
            return "未命名";
        }
        return names[Math.min(variant, names.length - 1)];
    }

    private void seedAdoptionRequests(List<User> users, List<Pet> pets, int desired) {
        List<User> applicants = users.stream().filter(user -> user.getRole() == User.Role.USER).toList();
        if (pets.isEmpty() || applicants.isEmpty()) {
            return;
        }
        List<AdoptionRequest> all = new ArrayList<>(adoptionRequestRepository.findAll());
        all.sort(Comparator.comparing(AdoptionRequest::getId));
        List<AdoptionRequest> dirty = new ArrayList<>();

        int normalizeCount = Math.min(all.size(), desired);
        for (int i = 0; i < normalizeCount; i++) {
            AdoptionRequest request = all.get(i);
            Pet pet = pets.get(i % pets.size());
            User applicant = applicants.get((i + 1) % applicants.size());
            request.setPetId(pet.getId());
            request.setOwnerId(pet.getOwnerId());
            request.setRequesterId(applicant.getId());
            request.setStatus(i % 7 == 0 ? AdoptionRequest.Status.APPROVED : AdoptionRequest.Status.PENDING);
            request.setContactName(safeName(applicant));
            request.setContactPhone("139" + String.format(Locale.ROOT, "%08d", 1000 + i));
            request.setMessage("我已经准备好了基础用品，也有稳定的作息时间，希望可以进一步了解 " + pet.getName() + " 的日常习惯。");
            dirty.add(request);
        }

        while (all.size() < desired) {
            int index = all.size();
            Pet pet = pets.get(index % pets.size());
            User applicant = applicants.get((index + 1) % applicants.size());
            AdoptionRequest request = new AdoptionRequest();
            request.setPetId(pet.getId());
            request.setOwnerId(pet.getOwnerId());
            request.setRequesterId(applicant.getId());
            request.setStatus(index % 7 == 0 ? AdoptionRequest.Status.APPROVED : AdoptionRequest.Status.PENDING);
            request.setContactName(safeName(applicant));
            request.setContactPhone("139" + String.format(Locale.ROOT, "%08d", 1000 + index));
            request.setMessage("家里已经完成封窗和休息区布置，希望可以申请领养 " + pet.getName() + "，后续也愿意接受回访。");
            all.add(request);
            dirty.add(request);
        }

        if (!dirty.isEmpty()) {
            adoptionRequestRepository.saveAll(dirty);
        }
    }

    private ProductTemplate productTemplate(int index) {
        int templateIndex = index % 12;
        int variant = index / 12;
        String suffix = switch (variant) {
            case 0 -> "";
            case 1 -> "·家庭装";
            case 2 -> "·轻享版";
            case 3 -> "·升级款";
            default -> "·精选款";
        };
        return switch (templateIndex) {
            case 0 -> new ProductTemplate("冻干鸭肉粒" + suffix, "高蛋白冻干零食，适合训练奖励与日常加餐。", "shop_banner_real_1", Product.ProductCategory.FOOD, money("59.00", variant), 98 + index * 2);
            case 1 -> new ProductTemplate("鸡肉全价猫粮" + suffix, "低敏配方，颗粒适口，适合幼猫与成猫。", "shop_real_3", Product.ProductCategory.FOOD, money("129.00", variant), 66 + index);
            case 2 -> new ProductTemplate("犬用益生菌粉" + suffix, "帮助肠胃调理，适合换粮期和敏感体质。", "shop_real_5", Product.ProductCategory.MEDICINE, money("79.00", variant), 58 + index);
            case 3 -> new ProductTemplate("自动喂食器" + suffix, "定时定量，支持远程查看喂食记录。", "shop_banner_real_2", Product.ProductCategory.ACCESSORY, money("199.00", variant), 42 + index);
            case 4 -> new ProductTemplate("互动逗猫棒套装" + suffix, "多种羽毛头替换，适合高频互动。", "pet_cat_real_3", Product.ProductCategory.TOY, money("39.90", variant), 120 + index * 2);
            case 5 -> new ProductTemplate("耐咬磨牙玩具" + suffix, "天然橡胶材质，适合中大型犬释压。", "pet_dog_real_3", Product.ProductCategory.TOY, money("49.00", variant), 90 + index);
            case 6 -> new ProductTemplate("梳毛按摩手套" + suffix, "梳毛按摩二合一，换毛季更省心。", "pet_dog_real_4", Product.ProductCategory.ACCESSORY, money("29.90", variant), 130 + index);
            case 7 -> new ProductTemplate("外出便携包" + suffix, "收纳零食、牵引绳与湿巾，出门好整理。", "shop_real_4", Product.ProductCategory.ACCESSORY, money("79.00", variant), 64 + index);
            case 8 -> new ProductTemplate("护毛洗护套装" + suffix, "温和洗护，适合长毛犬猫日常护理。", "pet_cat_real_4", Product.ProductCategory.ACCESSORY, money("88.00", variant), 52 + index);
            case 9 -> new ProductTemplate("猫抓板组合" + suffix, "波浪造型抓板，兼顾磨爪与休息。", "pet_cat_real_2", Product.ProductCategory.TOY, money("45.00", variant), 110 + index);
            case 10 -> new ProductTemplate("主食罐组合" + suffix, "多肉配方，补水适口，适合作为主食替换。", "shop_real_3", Product.ProductCategory.FOOD, money("69.00", variant), 88 + index);
            default -> new ProductTemplate("宠物营养膏" + suffix, "补充日常营养与微量元素，食欲差时也适用。", "shop_real_5", Product.ProductCategory.MEDICINE, money("55.00", variant), 72 + index);
        };
    }

    private PetTemplate petTemplate(int index, Long ownerId) {
        int templateIndex = index % 12;
        int variant = index / 12;
        return switch (templateIndex) {
            case 0 -> new PetTemplate(pickVariantName(variant, "小黑", "可乐", "阿布", "黑豆"), "狗", "柯基", "黄白", 2 + variant, Pet.Gender.MALE, "中", "活泼亲人，散步习惯稳定，适合有固定遛狗时间的家庭。", "pet_dog_real_1", availableStatus(index), cityByIndex(index), "希望领养家庭有基础养犬经验，能接受后续回访。", ownerId);
            case 1 -> new PetTemplate(pickVariantName(variant, "白雪", "奶油", "星星", "Lucky"), "狗", "金毛", "奶油", 3 + variant, Pet.Gender.FEMALE, "中", "性格温顺，对人友好，已经完成基础免疫和驱虫。", "pet_dog_real_2", availableStatus(index), cityByIndex(index), "适合家庭陪伴，优先考虑有稳定居住环境的申请人。", ownerId);
            case 2 -> new PetTemplate(pickVariantName(variant, "橘子", "阿橘", "柿饼", "小满"), "猫", "中华田园猫", "橘白", 1 + variant, Pet.Gender.MALE, "小", "爱撒娇、亲人，正在适应新环境，吃饭规律。", "pet_cat_real_1", availableStatus(index), cityByIndex(index), "希望能提供封窗环境和基础猫砂盆配置。", ownerId);
            case 3 -> new PetTemplate(pickVariantName(variant, "咪咪", "拿铁", "小雨", "灰灰"), "猫", "英短", "蓝灰", 2 + variant, Pet.Gender.FEMALE, "小", "安静独立，不挑食，对陌生环境适应较快。", "pet_cat_real_2", availableStatus(index), cityByIndex(index), "可接受上门回访，优先考虑有猫咪照顾经验的家庭。", ownerId);
            case 4 -> new PetTemplate(pickVariantName(variant, "豆包", "多多", "阿诺", "Cookie"), "狗", "拉布拉多", "米白", 2 + variant, Pet.Gender.MALE, "中", "运动量适中，社交表现稳定，已学会基础口令。", "pet_dog_real_3", availableStatus(index), cityByIndex(index), "需要规律遛狗和基础训练，适合陪伴时间充足的人。", ownerId);
            case 5 -> new PetTemplate(pickVariantName(variant, "年糕", "云朵", "糯米", "奶芙"), "猫", "布偶", "海豹双色", 3 + variant, Pet.Gender.FEMALE, "小", "毛发柔软，粘人度高，喜欢晒太阳和安静角落。", "pet_cat_real_3", availableStatus(index), cityByIndex(index), "建议准备梳毛工具和封闭阳台。", ownerId);
            case 6 -> new PetTemplate(pickVariantName(variant, "七七", "雪球", "团子", "奶昔"), "兔", "垂耳兔", "奶白", 1 + variant, Pet.Gender.FEMALE, "小", "性格温和，饮食稳定，适合安静家庭饲养。", "media_placeholder", availableStatus(index), cityByIndex(index), "需要准备围栏与干草，接受定期反馈饲养情况。", ownerId);
            case 7 -> new PetTemplate(pickVariantName(variant, "栗子", "摩卡", "布丁", "毛豆"), "狗", "泰迪", "棕色", 4 + variant, Pet.Gender.MALE, "小", "聪明活泼，喜欢互动，洗护配合度高。", "pet_dog_real_4", availableStatus(index), cityByIndex(index), "适合居家办公或陪伴时间较多的家庭。", ownerId);
            case 8 -> new PetTemplate(pickVariantName(variant, "芝麻", "可可", "花卷", "十三"), "猫", "美短", "银灰", 2 + variant, Pet.Gender.MALE, "小", "胆子不大，但熟悉后会主动贴近主人。", "pet_cat_real_4", availableStatus(index), cityByIndex(index), "需要耐心适应期，建议单猫家庭优先。", ownerId);
            case 9 -> new PetTemplate(pickVariantName(variant, "团团", "奶盖", "芋圆", "元宝"), "兔", "侏儒兔", "灰白", 1 + variant, Pet.Gender.MALE, "小", "日常安静，饮食规律，喜欢固定角落休息。", "media_placeholder", availableStatus(index), cityByIndex(index), "准备兔厕所和磨牙用品后更适合接回家。", ownerId);
            case 10 -> new PetTemplate(pickVariantName(variant, "奶酪", "花生", "布布", "糯球"), "仓鼠", "金丝熊", "金黄", 1, Pet.Gender.FEMALE, "小", "晚上活跃，习惯跑轮，适合第一次接触小宠的人。", "media_placeholder", availableStatus(index), cityByIndex(index), "希望新主人了解基础小宠喂养知识。", ownerId);
            default -> new PetTemplate(pickVariantName(variant, "乌龙", "大麦", "阿旺", "笨笨"), "狗", "中华田园犬", "黑白", 2 + variant, Pet.Gender.MALE, "中", "性格稳，适应力强，对陌生人观察后会逐渐放松。", "pet_dog_real_5", availableStatus(index), cityByIndex(index), "接受定期回访，优先考虑有独立居住环境的领养人。", ownerId);
        };
    }

    private PostTemplate postTemplate(int index, User.Role role, Long petId) {
        int templateIndex = index % 12;
        return switch (templateIndex) {
            case 0 -> new PostTemplate("春季换毛季护理经验分享", "最近门店遇到很多家长来咨询换毛季护理。我们总结了三点：规律梳毛、补充饮水、减少频繁洗澡。家里如果有长毛宠物，建议准备一把针梳和一把排梳，效果会比单独用手套更稳定。", null, petId);
            case 1 -> new PostTemplate("第一次带猫咪做体检，需要准备什么？", "如果是第一次到院体检，建议准备近期饮食情况、驱虫记录和疫苗本。到院后先让猫咪熟悉环境，情绪平稳后再做基础检查，结果会更准确。", null, petId);
            case 2 -> new PostTemplate("冻干零食怎么喂更合适？", "冻干零食更适合作为奖励，不建议直接代替主粮。体型较小的猫狗一次喂 3-5 粒就够了，最好搭配足够的饮水，避免吃得过急。", "shop_banner_real_1", petId);
            case 3 -> new PostTemplate("给领养家庭的一些建议", "如果你准备接一只成年的流浪宠物回家，前两周不要急着过度互动，先给它固定食盆、猫砂盆/休息区，让它知道家里哪些地方是安全的。", null, petId);
            case 4 -> new PostTemplate("狗狗刷牙真的有必要吗？", "很多口臭问题不是换粮就能解决的，牙结石和口腔炎症才是根源。小型犬更需要尽早建立刷牙习惯，至少每周 3 次，长期效果会非常明显。", null, petId);
            case 5 -> new PostTemplate("我家布偶最近爱躲床底，后来发现是这个原因", "天气转凉后，家里地暖没开，布偶开始更喜欢钻进狭小的地方休息。后来我给它换了一个封闭猫窝，情绪明显稳定了，也更愿意主动出来玩。", "pet_cat_real_3", petId);
            case 6 -> new PostTemplate("自动喂食器使用一个月后的真实体验", "适合经常加班的人，但前提是宠物本身吃饭规律。我们店里测试下来，颗粒粮直径过大时容易卡粮，所以购买前最好确认适配的粮型。", "shop_banner_real_2", petId);
            case 7 -> new PostTemplate("领养前最该问的问题，不是可不可爱", "比起外形，更重要的是：疫苗驱虫是否完成、是否能接受回访、是否有应激史、是否适合与原住民同住。把这些问清楚，领养后会少走很多弯路。", null, petId);
            case 8 -> new PostTemplate("今天带小黑去做了年度体检", "体检结果总体稳定，医生提醒我继续控制零食比例，多安排散步和嗅闻活动。顺便记录一下，小黑现在体重 11.2kg，状态比去年更好一些。", "pet_dog_real_1", petId);
            case 9 -> new PostTemplate("新手养兔，最容易忽略的是干草摄入", "兔兔不像猫狗那样只盯着主粮，干草量不足很容易影响肠胃和牙齿磨耗。建议固定补充提摩西草，观察排便形态，再决定是否需要调整饮食。", null, petId);
            case 10 -> new PostTemplate("最近比较好用的梳毛手套分享", "对短毛犬猫来说，梳毛手套比硬针梳更容易接受，尤其在换毛季。我们自己用了两周，静电少，清理也方便，比较适合日常基础护理。", "pet_dog_real_4", petId);
            default -> new PostTemplate(role == User.Role.PET_HOSPITAL ? "医院门诊常见问题整理" : "日常养宠记录", role == User.Role.PET_HOSPITAL ? "最近门诊里比较多的是皮肤问题和肠胃问题。家里如果突然换粮、换洗护或者天气变化明显，都可能让敏感体质的宠物先出现不适。" : "最近把作息和喂养时间重新固定下来后，家里的小家伙状态稳定了很多。记录一下，希望后面也能保持。", null, petId);
        };
    }

    private CommentTemplate commentTemplate(int index, Post post) {
        String[] comments = new String[]{
                "这条经验很实用，我也遇到过类似情况，回去准备按你的方法试试。",
                "我们家也差不多，关键还是先把作息和环境稳定下来。",
                "感谢分享，尤其是关于适应期和回访的提醒，很有帮助。",
                "这个建议真的有效，我家小家伙就是调整饮食后状态稳定下来的。",
                "如果后续还有更新，可以继续发一条，我很想看看长期效果。",
                "说得很细，尤其是新手最容易忽略的几个点都提到了。"
        };
        return new CommentTemplate(comments[index % comments.length], 1 + (index % 12));
    }

    private HealthTemplate healthTemplate(int index, Pet pet) {
        int templateIndex = index % 4;
        return switch (templateIndex) {
            case 0 -> new HealthTemplate(HealthRecord.RecordType.EXAMINATION, "年度体检", "精神状态稳定，心肺听诊正常，体重控制在理想范围内。", "贝克宠物医院 - 王医生", LocalDate.now().minusDays(60 + index));
            case 1 -> new HealthTemplate(HealthRecord.RecordType.VACCINATION, "疫苗加强", "已完成本年度疫苗加强，留观后无异常反应。", "贝克宠物医院 - 李医生", LocalDate.now().minusDays(120 + index));
            case 2 -> new HealthTemplate(HealthRecord.RecordType.GROOMING, "洗护护理", "皮肤状态良好，毛发顺滑度提升，建议继续保持定期洗护。", "城宠社区门店 - 护理师小王", LocalDate.now().minusDays(25 + index));
            default -> new HealthTemplate(HealthRecord.RecordType.MEDICATION, "驱虫记录", pet.getSpecies().contains("猫") ? "完成体内外驱虫，近期食欲与排便正常。" : "完成月度驱虫，户外活动前后建议继续检查耳道和脚垫。", "贝克宠物医院 - 赵医生", LocalDate.now().minusDays(15 + index));
        };
    }

    private void applyProductTemplate(Product product, ProductTemplate template) {
        product.setName(template.name());
        product.setDescription(template.description());
        product.setImage(template.imageKey());
        product.setCategory(template.category());
        product.setPrice(template.price());
        product.setStockQuantity(template.stock());
    }

    private void applyPetTemplate(Pet pet, PetTemplate template, Long ownerId) {
        pet.setName(template.name());
        pet.setSpecies(template.species());
        pet.setBreed(template.breed());
        pet.setColor(template.color());
        pet.setAge(template.age());
        pet.setGender(template.gender());
        pet.setSize(template.size());
        pet.setDescription(template.description());
        pet.setImage(template.imageKey());
        pet.setAdoptionStatus(template.status());
        pet.setAdoptionCity(template.city());
        pet.setAdoptionNote(template.note());
        pet.setBirthDate(LocalDate.now().minusYears(template.age()).minusDays(20));
        pet.setOwnerId(ownerId == null ? template.ownerId() : ownerId);
    }

    private void applyPostTemplate(Post post, PostTemplate template, Long userId) {
        post.setTitle(template.title());
        post.setContent(template.content());
        post.setUserId(userId);
        if (post.getPetId() == null) {
            post.setPetId(template.petId());
        }
        post.setImageUrls(template.imageUrls());
        if (post.getViewCount() == null || post.getViewCount() <= 0) {
            post.setViewCount(500 + ((int) ((post.getId() == null ? 1 : post.getId()) % 17) * 73));
        }
        if (post.getLikeCount() == null || post.getLikeCount() < 0) {
            post.setLikeCount(30);
        }
        if (post.getCommentCount() == null || post.getCommentCount() < 0) {
            post.setCommentCount(6);
        }
    }

    private void applyHealthTemplate(HealthRecord record, HealthTemplate template, Long petId) {
        record.setPetId(petId);
        record.setRecordType(template.type());
        record.setTitle(template.title());
        record.setDescription(template.description());
        record.setRecordDate(template.recordDate());
        record.setVeterinarian(template.veterinarian());
        if (template.type() == HealthRecord.RecordType.VACCINATION) {
            record.setNextDueDate(template.recordDate().plusYears(1));
        } else {
            record.setNextDueDate(null);
        }
    }

    private boolean isGeneratedProduct(Product product) {
        return blank(product.getName())
                || safe(product.getName()).startsWith("宠物商品-")
                || safe(product.getDescription()).contains("自动生成")
                || safe(product.getDescription()).contains("演示")
                || safe(product.getImage()).contains("example.com")
                || product.getCategory() == null
                || product.getPrice() == null;
    }

    private boolean isGeneratedPet(Pet pet) {
        return blank(pet.getName())
                || safe(pet.getName()).startsWith("宠物")
                || safe(pet.getDescription()).contains("自动生成")
                || safe(pet.getDescription()).contains("演示")
                || blank(pet.getImage());
    }

    private boolean isGeneratedPost(Post post) {
        return blank(post.getTitle())
                || safe(post.getTitle()).startsWith("帖子标题-")
                || safe(post.getContent()).contains("自动生成")
                || safe(post.getContent()).contains("演示")
                || safe(post.getImageUrls()).contains("example.com");
    }

    private boolean isGeneratedComment(Comment comment) {
        return safe(comment.getContent()).contains("自动生成") || safe(comment.getContent()).contains("评论内容（自动生成）");
    }

    private boolean isGeneratedHealthRecord(HealthRecord record) {
        return safe(record.getTitle()).startsWith("健康记录-")
                || safe(record.getDescription()).contains("自动生成")
                || safe(record.getDescription()).contains("演示");
    }

    private boolean isGeneratedOrder(Order order) {
        return safe(order.getShippingAddress()).startsWith("示例地址-")
                || blank(order.getContactPhone())
                || blank(order.getProductIds())
                || blank(order.getQuantities())
                || order.getTotalAmount() == null;
    }

    private boolean isValidBreedForSpecies(String species, String breed) {
        if (blank(species) || blank(breed)) {
            return false;
        }
        return switch (species) {
            case "狗" -> List.of("柯基", "金毛", "拉布拉多", "泰迪", "中华田园犬").contains(breed);
            case "猫" -> List.of("中华田园猫", "英短", "布偶", "美短").contains(breed);
            case "兔" -> List.of("垂耳兔", "侏儒兔").contains(breed);
            case "仓鼠" -> List.of("金丝熊").contains(breed);
            default -> false;
        };
    }

    private User findUserById(List<User> users, Long userId, User fallback) {
        if (userId == null) {
            return fallback;
        }
        return users.stream().filter(user -> userId.equals(user.getId())).findFirst().orElse(fallback);
    }

    private BigDecimal money(String base, int variant) {
        return new BigDecimal(base).add(BigDecimal.valueOf(variant * 4L));
    }

    private Pet.AdoptionStatus availableStatus(int index) {
        return index % 9 == 0 ? Pet.AdoptionStatus.PAUSED : Pet.AdoptionStatus.AVAILABLE;
    }

    private String cityByIndex(int index) {
        return CITIES[index % CITIES.length];
    }

    private String safeName(User user) {
        return blank(user.getNickname()) ? user.getUsername() : user.getNickname();
    }

    private boolean blank(String value) {
        return value == null || value.isBlank();
    }

    private String safe(String value) {
        return value == null ? "" : value;
    }

    private record ProductTemplate(String name, String description, String imageKey, Product.ProductCategory category, BigDecimal price, int stock) {}
    private record PetTemplate(String name, String species, String breed, String color, int age, Pet.Gender gender, String size, String description, String imageKey, Pet.AdoptionStatus status, String city, String note, Long ownerId) {}
    private record PostTemplate(String title, String content, String imageUrls, Long petId) {}
    private record CommentTemplate(String content, int likeCount) {}
    private record HealthTemplate(HealthRecord.RecordType type, String title, String description, String veterinarian, LocalDate recordDate) {}
}
