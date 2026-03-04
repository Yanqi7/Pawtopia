import { Comment, Page, Pet, Post, Product, ProductCategory, HealthRecord, Order, AdoptionRequest } from '../model/Models';

export class MockData {
  static postsPage(page: number, size: number): Page<Post> {
    const titles: string[] = [
      '今天给猫咪换了新窝',
      '求推荐适合幼犬的粮',
      '第一次带宠物体检的注意事项',
      '分享一下我家毛孩子的日常',
      '领养前要做哪些准备？',
      '猫砂盆除味小技巧'
    ];
    const bodies: string[] = [
      '最近天气转凉，给它换了厚一点的垫子，结果它一秒就躺平了。',
      '想给幼犬换粮，担心肠胃不适，有经验的朋友推荐一下吗？',
      '体检主要看什么项目？有没有必要做基础血检？',
      '每天最治愈的时刻就是它跑过来蹭我一下。',
      '准备领养一只小猫，想了解下必备物品清单与预算。',
      '试了小苏打+活性炭，感觉效果不错，也欢迎大家补充。'
    ];
    const all: Post[] = [];
    for (let i = 1; i <= 30; i++) {
      const t = titles[i % titles.length];
      const b = bodies[i % bodies.length];
      all.push({
        id: i,
        title: `${t}（#${i}）`,
        content: `${b}\n\n—— 来自城宠部落用户的分享`,
        userId: 1,
        likeCount: (i * 3) % 17,
        commentCount: (i * 5) % 9,
        viewCount: 100 + i
      });
    }
    return MockData.pageOf(all, page, size);
  }

  static postById(id: number): Post {
    const tips: string[] = [
      '如果你也有类似经历，欢迎留言交流。',
      '记录一下，过段时间再来回看会很有意思。',
      '小贴士：循序渐进是最稳妥的。'
    ];
    return {
      id,
      title: `分享帖 #${id}`,
      content: `今天随手记一条：和毛孩子相处的每一天都很幸福。\n\n${tips[id % tips.length]}`,
      userId: 1,
      likeCount: 3,
      commentCount: 1,
      viewCount: 120
    };
  }

  static commentsPage(postId: number, page: number, size: number): Page<Comment> {
    const all: Comment[] = [];
    const samples: string[] = [
      '太可爱了！我家也是同款反应。',
      '建议先少量过渡，观察两三天再增加比例。',
      '体检的话基础血常规+生化就很实用了。',
      '感谢分享，学到了。',
      '同问，蹲一个更详细的清单。'
    ];
    for (let i = 1; i <= 8; i++) {
      all.push({
        id: postId * 100 + i,
        postId,
        userId: 1,
        content: samples[i % samples.length],
        likeCount: i % 3
      });
    }
    return MockData.pageOf(all, page, size);
  }

  static productsPage(page: number, size: number): Page<Product> {
    const all: Product[] = [];
    const cats: ProductCategory[] = ['FOOD', 'TOY', 'ACCESSORY', 'MEDICINE', 'OTHER'];
    const names: string[] = [
      '冻干鸡肉粒',
      '互动逗猫棒',
      '耐咬磨牙玩具',
      '宠物梳毛手套',
      '日常护理湿巾',
      '营养补充软糖'
    ];
    const descs: string[] = [
      '高蛋白配方，适口性好。',
      '弹力绳设计，解放双手。',
      '加厚材质，陪它玩更久。',
      '轻松去浮毛，适合换毛季。',
      '温和无刺激，外出必备。',
      '日常补充，按说明喂食。'
    ];
    for (let i = 1; i <= 40; i++) {
      all.push({
        id: i,
        name: `${names[i % names.length]}（#${i}）`,
        description: descs[i % descs.length],
        price: (9.9 + i).toFixed(2),
        stockQuantity: 99,
        category: cats[i % cats.length]
      });
    }
    return MockData.pageOf(all, page, size);
  }

  static productById(id: number): Product {
    return {
      id,
      name: `精选商品 #${id}`,
      description: '适合日常囤货与宠物护理使用。',
      price: '19.90',
      stockQuantity: 99,
      category: 'OTHER'
    };
  }

  static petsAll(): Pet[] {
    const all: Pet[] = [];
    const petNames: string[] = ['团子', '豆包', '小虎', '奶糖', '可乐', '麻薯', '小满', '元宝'];
    const breedsCat: string[] = ['英短', '美短', '布偶', '橘猫', '中华田园'];
    const breedsDog: string[] = ['柯基', '金毛', '柴犬', '泰迪', '中华田园'];
    const stories: string[] = [
      '性格亲人，熟悉后会主动蹭人。',
      '有点胆小，需要耐心适应新环境。',
      '会定点上厕所，习惯很好。',
      '喜欢晒太阳和小零食，吃饭不挑。',
      '精力旺盛，适合喜欢运动的家庭。'
    ];
    for (let i = 1; i <= 12; i++) {
      const isCat = i % 2 === 0;
      all.push({
        id: i,
        name: petNames[i % petNames.length] + `${i}`,
        species: isCat ? '猫' : '狗',
        breed: isCat ? breedsCat[i % breedsCat.length] : breedsDog[i % breedsDog.length],
        age: 1 + (i % 6),
        gender: i % 2 === 0 ? 'FEMALE' : 'MALE',
        description: stories[i % stories.length] + ' 已做基础驱虫，欢迎了解。',
        adoptionStatus: i % 7 === 0 ? 'PAUSED' : 'AVAILABLE',
        adoptionCity: i % 3 === 0 ? '北京' : '上海',
        adoptionNote: '希望领养人稳定居住，可接受回访。',
        ownerId: 1000 + (i % 3)
      });
    }
    return all;
  }

  static petById(id: number): Pet {
    const all = MockData.petsAll();
    const found = all.find((p) => p.id === id);
    return found ?? all[0];
  }

  static adoptionRequestsByPet(petId: number, ownerId: number): AdoptionRequest[] {
    return [
      {
        id: petId * 10 + 1,
        petId,
        ownerId,
        requesterId: 2001,
        status: 'PENDING',
        message: '家里有封窗，有养猫经验，愿意按时疫苗。',
        contactName: '小李',
        contactPhone: '13800138000'
      },
      {
        id: petId * 10 + 2,
        petId,
        ownerId,
        requesterId: 2002,
        status: 'PENDING',
        message: '工作稳定，平时在家办公，可以陪伴。',
        contactName: '阿文',
        contactPhone: '13900139000'
      }
    ];
  }

  static healthRecordsByPet(petId: number): HealthRecord[] {
    return [
      {
        id: petId * 100 + 1,
        petId,
        recordType: 'EXAMINATION',
        title: '年度体检',
        description: '体重正常，精神状态良好，建议保持规律运动与饮食。',
        recordDate: '2026-02-01'
      }
    ];
  }

  static ordersByUser(userId: number): Order[] {
    return [
      {
        id: 1,
        userId,
        productIds: '1,2',
        quantities: '1,1',
        totalAmount: '39.80',
        status: 'PENDING',
        shippingAddress: '海淀区示例路 88 号',
        contactName: '张三',
        contactPhone: '13800000000'
      }
    ];
  }

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
