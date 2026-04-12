import { Comment, Page, Pet, Post, Product, ProductCategory, HealthRecord, Order, AdoptionRequest, PetMessage, User } from '../model/Models';

export class MockData {
  // ============ 用户数据 ============
  static getUsers(): User[] {
    return [
      {
        id: 1,
        username: 'petcare_pro',
        nickname: '宠物护理专家',
        email: 'petcare@example.com',
        role: 'USER',
        avatar: '👩'
      },
      {
        id: 1001,
        username: 'beike_hospital',
        nickname: '贝克宠物医院',
        email: 'beike@hospital.com',
        role: 'PET_HOSPITAL',
        avatar: '🏥'
      },
      {
        id: 1002,
        username: 'happy_pet_shop',
        nickname: '快乐宠物店',
        email: 'happy@petshop.com',
        role: 'PET_SHOP',
        avatar: '🐾'
      },
      {
        id: 1003,
        username: 'anji_seller',
        nickname: '爱宠小卖部',
        email: 'anji@seller.com',
        role: 'SELLER',
        avatar: '🛒'
      },
      {
        id: 1004,
        username: 'dog_lover_zhang',
        nickname: '养狗的张姐',
        email: 'zhang@user.com',
        role: 'USER',
        avatar: '👱‍♀️'
      },
      {
        id: 1005,
        username: 'cat_fancier_li',
        nickname: '猫咪发烧友',
        email: 'li@user.com',
        role: 'USER',
        avatar: '👨'
      }
    ];
  }

  // ============ 社区帖子数据 ============
  static postsPage(page: number, size: number): Page<Post> {
    const posts: Post[] = [
      // 医院发布的内容
      {
        id: 1,
        title: '春季宠物过敏症状及预防指南',
        content: '春季是宠物过敏的高发期。常见症状包括皮肤瘙痒、掉毛、耳朵发炎等。建议：\n1. 定期梳毛，去除死毛\n2. 使用宠物专用洗液\n3. 及时体检检查\n\n若有严重过敏反应，请及时就医。欢迎咨询我们的医生。',
        userId: 1001,
        likeCount: 156,
        commentCount: 24,
        viewCount: 1280,
        createdAt: '2026-03-28'
      },
      {
        id: 2,
        title: '疫苗接种时间表 | 确保你的宠物健康成长',
        content: '新手主人看过来！宠物疫苗接种很重要：\n\n幼犬/幼猫（8周后）：首次五联/三联\n12周：第二次疫苗\n16周：第三次疫苗\n成年后：每年加强一次\n\n狂犬病疫苗务必接种。欢迎预约体检。',
        userId: 1001,
        likeCount: 203,
        commentCount: 38,
        viewCount: 2105,
        createdAt: '2026-03-27'
      },
      // 商家发布的内容
      {
        id: 3,
        title: '新到货！进口高品质冻干零食',
        content: '【新品上市】法国进口冻干鸭肉粒\n✓ 100%天然肉类，无添加\n✓ 营养丰富，猫狗都爱吃\n✓ 原价89元，今日特价59元\n\n库存有限，先到先得！本店可送货上门，下单即发。',
        userId: 1002,
        likeCount: 89,
        commentCount: 15,
        viewCount: 756,
        createdAt: '2026-03-26'
      },
      {
        id: 4,
        title: '春季美容套餐上线啦 | 让毛孩子焕然一新',
        content: '迎接春天，给宠物来个大改变！\n\n【春季美容套餐】\n🐕 犬类基础洗护：¥88\n🐈 猫咪SPA护理：¥128\n✨ 含毛质护理精油\n\n门店位置：朝阳区建国路88号\n预约电话：010-8888-8888',
        userId: 1002,
        likeCount: 67,
        commentCount: 12,
        viewCount: 543,
        createdAt: '2026-03-25'
      },
      // 卖家发布的内容
      {
        id: 5,
        title: '热卖爆款 | 智能宠物喂食器现货充足',
        content: '🎁 【热销王】智能宠物自动喂食器\n✓ 定时定量，再也不用手动喂\n✓ 容量2L，可养2-3只宠物\n✓ APP控制，随时随地喂宠物\n\n原价299元 → 现价199元\n已售3000+，好评率98%\n支持货到付款、7天无理由退换',
        userId: 1003,
        likeCount: 234,
        commentCount: 41,
        viewCount: 3210,
        createdAt: '2026-03-24'
      },
      // 普通用户发布的内容
      {
        id: 6,
        title: '我家金毛的日常|每一刻都萌萌哒',
        content: '我家的金毛"球球"今年3岁了，性格特别温顺。\n\n最喜欢的日常就是：\n📸 早上散步晒太阳\n🎾 下午陪我运动\n🛋️ 晚上窝在沙发上\n\n有没有养金毛的姐妹？来分享你们的故事呀',
        userId: 1004,
        likeCount: 312,
        commentCount: 67,
        viewCount: 4156,
        createdAt: '2026-03-23'
      },
      {
        id: 7,
        title: '初养猫咪，请问这些费用正常吗？',
        content: '刚领养了一只3个月大的小橘猫"咪咪"，咨询一下各位老养猫人：\n\n💰 月均开销：\n猫粮/罐头：120元\n猫砂：50元\n玩具/零食：80元\n\n这样算下来一个月快300块了，是不是有点多？还有其他省钱建议吗？',
        userId: 1005,
        likeCount: 178,
        commentCount: 53,
        viewCount: 2341,
        createdAt: '2026-03-22'
      }
    ];

    return MockData.pageOf(posts, page, size);
  }

  static postById(id: number): Post {
    const posts = MockData.postsPage(0, 100).content;
    return posts.find(p => p.id === id) || posts[0];
  }

  // ============ 评论数据 ============
  static commentsPage(postId: number, page: number, size: number): Page<Comment> {
    const comments: Comment[] = [
      {
        id: postId * 100 + 1,
        postId,
        userId: 1005,
        content: '感谢医院的专业指导！我家猫咪最近也有皮肤瘙痒，正好预约你们',
        likeCount: 12,
        createdAt: '2026-03-28'
      },
      {
        id: postId * 100 + 2,
        postId,
        userId: 1004,
        content: '疫苗是真的重要，我家狗狗按时打疫苗已经5年没生过病了',
        likeCount: 8,
        createdAt: '2026-03-28'
      },
      {
        id: postId * 100 + 3,
        postId,
        userId: 1002,
        content: '我们店里就有贝克医院推荐的这个品牌，确实很不错！',
        likeCount: 15,
        createdAt: '2026-03-27'
      },
      {
        id: postId * 100 + 4,
        postId,
        userId: 1001,
        content: '楼主做得很好，疫苗确实不能省',
        likeCount: 5,
        createdAt: '2026-03-27'
      }
    ];
    return MockData.pageOf(comments, page, size);
  }

  // ============ 商品数据 ============
  static productsPage(page: number, size: number): Page<Product> {
    const products: Product[] = [
      {
        id: 1,
        name: '法国进口冻干鸭肉粒',
        description: '100%天然肉类，无谷无添加，高蛋白',
        price: '59.00',
        stockQuantity: 156,
        category: 'FOOD',
        createdAt: '2026-03-20'
      },
      {
        id: 2,
        name: '猫咪SPA护理套装',
        description: '含护理精油+洗毛液+护肤霜，专业美容师推荐',
        price: '128.00',
        stockQuantity: 43,
        category: 'ACCESSORY',
        createdAt: '2026-03-19'
      },
      {
        id: 3,
        name: '智能宠物自动喂食器',
        description: '定时定量，APP控制，容量2L，适合2-3只宠物',
        price: '199.00',
        stockQuantity: 78,
        category: 'ACCESSORY',
        createdAt: '2026-03-18'
      },
      {
        id: 4,
        name: '宠物益生菌粉',
        description: '改善肠道消化，强化免疫力，适合所有年龄段',
        price: '89.00',
        stockQuantity: 92,
        category: 'MEDICINE',
        createdAt: '2026-03-17'
      },
      {
        id: 5,
        name: '互动逗猫棒（8根装）',
        description: '配不同羽毛和铃铛，开发智力，增进互动',
        price: '39.90',
        stockQuantity: 234,
        category: 'TOY',
        createdAt: '2026-03-16'
      },
      {
        id: 6,
        name: '耐咬磨牙玩具',
        description: '加厚天然橡胶，耐咬耐摔，适合大型犬',
        price: '49.00',
        stockQuantity: 67,
        category: 'TOY',
        createdAt: '2026-03-15'
      },
      {
        id: 7,
        name: '狗狗梳毛手套',
        description: '防脱毛，按摩梳毛二合一，软胶材质',
        price: '29.90',
        stockQuantity: 189,
        category: 'ACCESSORY',
        createdAt: '2026-03-14'
      },
      {
        id: 8,
        name: '宠物外出便携包',
        description: '防水透气，可装粮食玩具，出门必备',
        price: '79.00',
        stockQuantity: 45,
        category: 'ACCESSORY',
        createdAt: '2026-03-13'
      }
    ];
    return MockData.pageOf(products, page, size);
  }

  static productById(id: number): Product {
    const products = MockData.productsPage(0, 100).content;
    return products.find(p => p.id === id) || products[0];
  }

  // ============ 宠物数据（可领养） ============
  static petsAll(): Pet[] {
    return [
      {
        id: 1,
        name: '小黑',
        species: '狗',
        breed: '柯基',
        gender: 'MALE',
        age: 2,
        description: '性格活泼，已做驱虫，适合喜欢运动的家庭',
        image: 'pet_dog_real_1',
        adoptionStatus: 'AVAILABLE',
        adoptionCity: '北京',
        adoptionNote: '希望住在独立房屋或大公寓，可接受定期回访',
        ownerId: 1001,
        createdAt: '2026-03-20'
      },
      {
        id: 2,
        name: '白雪',
        species: '狗',
        breed: '金毛',
        gender: 'FEMALE',
        age: 3,
        description: '温顺懂事，已打齐疫苗，非常亲人',
        image: 'pet_dog_real_2',
        adoptionStatus: 'AVAILABLE',
        adoptionCity: '北京',
        adoptionNote: '优先考虑有饲养经验的家庭',
        ownerId: 1002,
        createdAt: '2026-03-19'
      },
      {
        id: 3,
        name: '橘子',
        species: '猫',
        breed: '橘猫',
        gender: 'MALE',
        age: 1,
        description: '调皮捣蛋，粘人，幼猫一枚，需要耐心教养',
        image: 'pet_cat_real_1',
        adoptionStatus: 'AVAILABLE',
        adoptionCity: '上海',
        adoptionNote: '需要有人在家照顾，接受回访',
        ownerId: 1003,
        createdAt: '2026-03-18'
      },
      {
        id: 4,
        name: '咪咪',
        species: '猫',
        breed: '英短',
        gender: 'FEMALE',
        age: 2,
        description: '独立安静，不爱闹，是上班族的好伴侣',
        image: 'pet_cat_real_2',
        adoptionStatus: 'AVAILABLE',
        adoptionCity: '北京',
        adoptionNote: '环境要求不高，但需要定期陪伴',
        ownerId: 1004,
        createdAt: '2026-03-17'
      }
    ];
  }

  static petById(id: number): Pet {
    const all = MockData.petsAll();
    return all.find(p => p.id === id) || all[0];
  }

  // ============ 领养申请 ============
  static adoptionRequestsByPet(petId: number, ownerId: number): AdoptionRequest[] {
    return [
      {
        id: petId * 10 + 1,
        petId,
        ownerId,
        requesterId: 1005,
        status: 'PENDING',
        message: '家里有大房子，已养过两只狗，经验丰富。我会给它最好的生活。',
        contactName: '李女士',
        contactPhone: '13800138000',
        createdAt: '2026-03-27'
      },
      {
        id: petId * 10 + 2,
        petId,
        ownerId,
        requesterId: 1004,
        status: 'PENDING',
        message: '工作稳定，在家办公，可以给予充分陪伴。',
        contactName: '张先生',
        contactPhone: '13900139000',
        createdAt: '2026-03-26'
      }
    ];
  }

  // ============ 健康记录 ============
  static healthRecordsByPet(petId: number): HealthRecord[] {
    return [
      {
        id: petId * 100 + 1,
        petId,
        recordType: 'EXAMINATION',
        title: '年度体检',
        description: '体重正常，精神状态良好，各项指标正常。建议保持规律运动与饮食。',
        recordDate: '2026-02-15',
        veterinarian: '贝克宠物医院 - 王医生',
        createdAt: '2026-02-15'
      },
      {
        id: petId * 100 + 2,
        petId,
        recordType: 'VACCINATION',
        title: '疫苗接种',
        description: '五联疫苗加强针',
        recordDate: '2026-01-10',
        nextDueDate: '2027-01-10',
        veterinarian: '贝克宠物医院 - 李医生',
        createdAt: '2026-01-10'
      },
      {
        id: petId * 100 + 3,
        petId,
        recordType: 'GROOMING',
        title: '美容护理',
        description: '定期洗澡护理，毛发护理精油护理',
        recordDate: '2026-03-15',
        veterinarian: '快乐宠物店 - 美容师小王',
        createdAt: '2026-03-15'
      }
    ];
  }

  static petMessagesByPet(petId: number): PetMessage[] {
    const pet = MockData.petById(petId);
    return [
      {
        id: petId * 1000 + 1,
        petId,
        authorName: '南瓜麻麻',
        content: `${pet.name}看起来状态很好，想了解它现在的作息和是否适应与小朋友同住。`,
        createdAt: '2026-03-26'
      },
      {
        id: petId * 1000 + 2,
        petId,
        authorName: '海边遛狗人',
        content: '我家已经有一只性格温和的原住民，如果可以的话希望安排一次线下见面。',
        createdAt: '2026-03-24'
      },
      {
        id: petId * 1000 + 3,
        petId,
        authorName: '猫窝计划',
        content: '已准备好封窗和独立休息区，也能接受回访。若有特殊饮食习惯请告诉我。',
        createdAt: '2026-03-21'
      }
    ];
  }

  // ============ 订单数据 ============
  static ordersByUser(userId: number): Order[] {
    return [
      {
        id: 1,
        userId,
        productIds: '1,5',
        quantities: '2,1',
        totalAmount: '148.80',
        status: 'SHIPPED',
        shippingAddress: '朝阳区建国路 88 号',
        contactName: '李女士',
        contactPhone: '13800000000',
        createdAt: '2026-03-20'
      },
      {
        id: 2,
        userId,
        productIds: '3',
        quantities: '1',
        totalAmount: '199.00',
        status: 'PENDING',
        shippingAddress: '海淀区中关村 1 号',
        contactName: '李女士',
        contactPhone: '13800000000',
        createdAt: '2026-03-25'
      }
    ];
  }

  static decoratePosts(posts: Post[]): Post[] {
    return posts.map((post: Post) => MockData.decoratePost(post));
  }

  static decoratePost(post: Post): Post {
    return {
      id: post.id,
      title: post.title,
      content: post.content,
      userId: post.userId,
      petId: post.petId,
      likeCount: post.likeCount,
      commentCount: post.commentCount,
      viewCount: post.viewCount,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
      imageUrls: post.imageUrls
    };
  }

  static decoratePets(pets: Pet[]): Pet[] {
    return pets.map((pet: Pet) => MockData.decoratePet(pet));
  }

  static decoratePet(pet: Pet): Pet {
    return {
      id: pet.id,
      name: pet.name,
      species: pet.species,
      breed: pet.breed,
      color: pet.color,
      age: pet.age,
      gender: pet.gender,
      size: pet.size,
      description: pet.description,
      image: pet.image,
      adoptionStatus: pet.adoptionStatus,
      adoptionCity: pet.adoptionCity,
      adoptionNote: pet.adoptionNote,
      birthDate: pet.birthDate,
      ownerId: pet.ownerId,
      createdAt: pet.createdAt,
      updatedAt: pet.updatedAt
    };
  }

  static decorateProducts(products: Product[]): Product[] {
    return products.map((product: Product) => MockData.decorateProduct(product));
  }

  static decorateProduct(product: Product): Product {
    return {
      id: product.id,
      name: product.name,
      description: product.description,
      image: product.image,
      price: product.price,
      stockQuantity: product.stockQuantity,
      category: product.category,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt
    };
  }

  static postImageKey(seed?: number): string {
    const keys = ['pet_cat_real_2', 'pet_dog_real_1', 'pet_cat_real_4', 'pet_dog_real_4', 'pet_dog_real_3'];
    return keys[Math.abs(seed ?? 0) % keys.length];
  }

  static petImageKey(seed?: number, species?: string): string {
    const cats = ['pet_cat_real_1', 'pet_cat_real_2', 'pet_cat_real_3', 'pet_cat_real_4'];
    const dogs = ['pet_dog_real_1', 'pet_dog_real_2', 'pet_dog_real_3', 'pet_dog_real_4', 'pet_dog_real_5'];
    const pool = (species ?? '').indexOf('猫') >= 0 ? cats : dogs;
    return pool[Math.abs(seed ?? 0) % pool.length];
  }

  static productImageKey(seed?: number, category?: ProductCategory): string {
    switch (category) {
      case 'FOOD':
        return Math.abs(seed ?? 0) % 3 === 0 ? 'shop_banner_real_1' : Math.abs(seed ?? 0) % 3 === 1 ? 'shop_real_3' : 'shop_real_5';
      case 'TOY':
        return Math.abs(seed ?? 0) % 2 === 0 ? 'shop_real_4' : 'shop_banner_real_2';
      case 'MEDICINE':
        return Math.abs(seed ?? 0) % 2 === 0 ? 'shop_real_5' : 'shop_banner_real_2';
      case 'ACCESSORY':
        return Math.abs(seed ?? 0) % 3 === 0 ? 'shop_real_4' : Math.abs(seed ?? 0) % 3 === 1 ? 'shop_banner_real_2' : 'shop_real_3';
      default:
        return Math.abs(seed ?? 0) % 2 === 0 ? 'shop_banner_real_1' : 'shop_real_3';
    }
  }

  // ============ 分页工具 ============
  private static pageOf<T>(all: T[], page: number, size: number): Page<T> {
    const start = Math.max(0, page) * Math.max(1, size);
    const end = Math.min(all.length, start + Math.max(1, size));
    const content = all.slice(start, end);
    const totalElements = all.length;
    const totalPages = Math.max(1, Math.ceil(totalElements / Math.max(1, size)));
    return {
      content,
      totalElements,
      totalPages,
      number: page,
      size,
      first: page <= 0,
      last: page >= totalPages - 1,
      empty: content.length === 0
    };
  }
}
