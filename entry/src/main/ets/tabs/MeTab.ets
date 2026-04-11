import { AppRouter } from '../common/AppRouter';
import { SessionStore } from '../store/SessionStore';
import { Api } from '../api/Api';
import { User, AdoptionRequest, Order, Pet, Post, UserRole } from '../model/Models';
import { AppStatus } from '../app/AppStatus';
import { AppPrompt } from '../common/AppPrompt';
import { Theme } from '../common/Theme';
import { CartStore } from '../store/CartStore';
import { EmptyState, OfflineBanner, QuickActionGrid, QuickActionItem, SectionHeader, StatsRow, UserHeader } from '../components/Ui';

type CommunityRouteMode = 'RECOMMEND' | 'MINE' | 'CARE' | 'SHOP' | 'LIFE';
type AdoptRouteFilter = 'ALL' | 'MINE';
type MallRouteView = 'ALL' | 'MINE';

interface MainTabParams {
  tab?: number;
  communityMode?: CommunityRouteMode;
  adoptFilter?: AdoptRouteFilter;
  mallView?: MallRouteView;
}

interface MyAdoptionsParams {
  mode?: 'MINE' | 'OWNED';
}

interface AdminPetsParams {
  mode?: 'PROFILE' | 'ADOPT';
}

@Component
export struct MeTab {
  @State private user?: User = SessionStore.getUser();
  @State private loading: boolean = false;
  @State private postCount: number = 0;
  @State private petCount: number = 0;
  @State private orderCount: number = 0;
  @State private adoptionCount: number = 0;

  aboutToAppear(): void {
    AppRouter.bind(this);
    this.user = SessionStore.getUser();
    this.loadSummary();
  }

  private role(): UserRole {
    return (this.user?.role ?? 'USER') as UserRole;
  }

  private async loadSummary(): Promise<void> {
    const currentUser = SessionStore.getUser();
    if (!currentUser || !currentUser.id) {
      this.postCount = 0;
      this.petCount = 0;
      this.orderCount = 0;
      this.adoptionCount = 0;
      return;
    }
    this.loading = true;
    try {
      const userId = currentUser.id;
      const postPromise = Api.getUserPosts(userId).catch(() => [] as Post[]);
      const petPromise = this.role() === 'PET_HOSPITAL'
        ? Api.getAllPets().then((pets: Pet[]) => pets.filter((pet: Pet) => pet.authorizedHospitalId === userId)).catch(() => [] as Pet[])
        : Api.getMyPets(userId).catch(() => [] as Pet[]);
      const orderPromise = this.role() === 'SELLER'
        ? Api.getSellerOrders(userId).catch(() => [] as Order[])
        : this.role() === 'ADMIN'
          ? Api.getAdminOrders('ALL').catch(() => [] as Order[])
          : Api.getMyOrders(userId).catch(() => [] as Order[]);
      const adoptionPromise = this.role() === 'PET_SHOP' || this.role() === 'ADMIN'
        ? Api.getOwnedAdoptionRequests().catch(() => [] as AdoptionRequest[])
        : Api.getMyAdoptionRequests().catch(() => [] as AdoptionRequest[]);
      const result = await Promise.all([postPromise, petPromise, orderPromise, adoptionPromise]);
      this.postCount = result[0].length;
      this.petCount = result[1].length;
      this.orderCount = result[2].length;
      this.adoptionCount = result[3].length;
    } catch (e) {
    } finally {
      this.loading = false;
    }
  }

  private async logout(): Promise<void> {
    await SessionStore.logout();
    AppRouter.replace('pages/Login', undefined, this);
  }

  private async clearCache(): Promise<void> {
    await CartStore.clear();
    AppPrompt.toast('购物车缓存已清空', this);
  }

  private navigateTab(tab: number, patch?: MainTabParams): void {
    const params: MainTabParams = {
      tab: tab,
      communityMode: patch?.communityMode,
      adoptFilter: patch?.adoptFilter,
      mallView: patch?.mallView
    };
    AppRouter.replace('pages/MainTabs', params, this);
  }

  private openAdoptionCenter(): void {
    const mode: 'MINE' | 'OWNED' = this.role() === 'PET_SHOP' || this.role() === 'ADMIN' ? 'OWNED' : 'MINE';
    AppRouter.push('pages/MyAdoptions', { mode: mode } as MyAdoptionsParams, this);
  }

  private commonActions(): QuickActionItem[] {
    return [
      {
        key: 'profile',
        title: '资料编辑',
        subtitle: '修改昵称、手机号和服务器地址',
        icon: $r('app.media.tab_me'),
        tone: 'blue',
        action: () => AppRouter.push('pages/ProfileSettings', undefined, this)
      },
      {
        key: 'posts',
        title: '我的发布',
        subtitle: '查看社区发帖和互动记录',
        icon: $r('app.media.tab_community'),
        tone: 'orange',
        action: () => this.navigateTab(0, { communityMode: 'MINE' })
      },
      {
        key: 'orders',
        title: '订单中心',
        subtitle: '查看下单、履约与状态流转',
        icon: $r('app.media.tab_mall'),
        tone: 'pink',
        action: () => AppRouter.push('pages/Orders', undefined, this)
      },
      {
        key: 'adopt',
        title: '领养申请',
        subtitle: '跟踪我的申请或我收到的申请',
        icon: $r('app.media.tab_adopt'),
        tone: 'blue',
        action: () => this.openAdoptionCenter()
      }
    ];
  }

  private roleActions(): QuickActionItem[] {
    if (this.role() === 'SELLER') {
      return [
        {
          key: 'seller-products',
          title: '我的商品',
          subtitle: '切到商城查看卖家商品视图',
          icon: $r('app.media.tab_mall'),
          tone: 'orange',
          action: () => AppRouter.push('pages/SellerProducts', undefined, this)
        },
        {
          key: 'seller-new-product',
          title: '上新商品',
          subtitle: '快速创建新的商城商品',
          icon: $r('app.media.hero_compose'),
          tone: 'blue',
          action: () => AppRouter.push('pages/NewProduct', undefined, this)
        },
        {
          key: 'seller-orders',
          title: '订单履约',
          subtitle: '处理待发货与运输中的订单',
          icon: $r('app.media.hero_feed'),
          tone: 'pink',
          action: () => AppRouter.push('pages/Orders', undefined, this)
        }
      ];
    }
    if (this.role() === 'PET_HOSPITAL') {
      return [
        {
          key: 'hospital-records',
          title: '档案工作台',
          subtitle: '查看授权宠物与即将到期记录',
          icon: $r('app.media.tab_health'),
          tone: 'blue',
          action: () => this.navigateTab(2)
        },
        {
          key: 'hospital-role',
          title: '角色入口',
          subtitle: '查看医院工作台说明与导航',
          icon: $r('app.media.hero_bell'),
          tone: 'orange',
          action: () => AppRouter.push('pages/RoleWorkbench', undefined, this)
        }
      ];
    }
    if (this.role() === 'PET_SHOP') {
      return [
        {
          key: 'shop-adopt',
          title: '领养发布',
          subtitle: '管理我发布的宠物与审批入口',
          icon: $r('app.media.tab_adopt'),
          tone: 'pink',
          action: () => this.navigateTab(1, { adoptFilter: 'MINE' })
        },
        {
          key: 'shop-role',
          title: '店铺工作台',
          subtitle: '查看当前角色可用入口',
          icon: $r('app.media.hero_feed'),
          tone: 'orange',
          action: () => AppRouter.push('pages/RoleWorkbench', undefined, this)
        }
      ];
    }
    if (this.role() === 'ADMIN') {
      return [
        {
          key: 'admin-users',
          title: '用户管理',
          subtitle: '创建角色账号并清理无效用户',
          icon: $r('app.media.tab_me'),
          tone: 'blue',
          action: () => AppRouter.push('pages/AdminUsers', undefined, this)
        },
        {
          key: 'admin-content',
          title: '内容巡检',
          subtitle: '查看帖子详情并清理异常内容',
          icon: $r('app.media.tab_community'),
          tone: 'orange',
          action: () => AppRouter.push('pages/AdminContent', undefined, this)
        },
        {
          key: 'admin-products',
          title: '商品管理',
          subtitle: '维护商品信息与分类标签',
          icon: $r('app.media.tab_mall'),
          tone: 'blue',
          action: () => AppRouter.push('pages/SellerProducts', undefined, this)
        },
        {
          key: 'admin-pets',
          title: '宠物档案管理',
          subtitle: '编辑全量宠物档案信息',
          icon: $r('app.media.tab_health'),
          tone: 'orange',
          action: () => AppRouter.push('pages/AdminPets', { mode: 'PROFILE' } as AdminPetsParams, this)
        },
        {
          key: 'admin-adoptions',
          title: '领养信息管理',
          subtitle: '管理公开领养信息与状态',
          icon: $r('app.media.tab_adopt'),
          tone: 'pink',
          action: () => AppRouter.push('pages/AdminPets', { mode: 'ADOPT' } as AdminPetsParams, this)
        },
        {
          key: 'admin-orders',
          title: '系统订单',
          subtitle: '查看全量订单状态',
          icon: $r('app.media.tab_mall'),
          tone: 'pink',
          action: () => AppRouter.push('pages/Orders', undefined, this)
        }
      ];
    }
    return [];
  }

  build() {
    Column() {
      if (!this.user) {
        EmptyState({
          title: '登录后查看你的宠物生活',
          description: '你可以管理宠物档案、领养申请、商城订单和社区内容。',
          actionText: '立即登录',
          action: () => AppRouter.push('pages/Login', undefined, this)
        })
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Column({ space: 14 }) {
              UserHeader({ user: this.user, statusText: AppStatus.isBackendOnline() ? '云端已连接' : '服务受限' })
              StatsRow({
                items: [
                  { key: 'post', label: '帖子', value: this.postCount, action: () => this.navigateTab(0, { communityMode: 'MINE' }) },
                  { key: 'pet', label: '宠物', value: this.petCount, action: () => this.navigateTab(2) },
                  { key: 'order', label: '订单', value: this.orderCount, action: () => AppRouter.push('pages/Orders', undefined, this) },
                  { key: 'adopt', label: '领养', value: this.adoptionCount, action: () => this.openAdoptionCenter() }
                ]
              })
            }
            .padding(14)
            .backgroundColor(Color.White)
            .border({ width: 1, color: Theme.border })
            .borderRadius(20)

            if (!AppStatus.isBackendOnline()) {
              OfflineBanner({ text: '当前无法连接服务，个人数据与统计可能不是最新状态。', action: () => this.loadSummary() })
            }

            Column({ space: 12 }) {
              SectionHeader({ title: '常用服务', subtitle: '资料、内容、订单与领养统一收口。' })
              QuickActionGrid({ items: this.commonActions() })
            }
            .padding(14)
            .backgroundColor(Color.White)
            .border({ width: 1, color: Theme.border })
            .borderRadius(20)

            if (this.roleActions().length > 0) {
              Column({ space: 12 }) {
                SectionHeader({ title: '角色工作台', subtitle: '当前身份直接影响可见入口与可操作能力。' })
                QuickActionGrid({ items: this.roleActions() })
              }
              .padding(14)
              .backgroundColor(Color.White)
              .border({ width: 1, color: Theme.border })
              .borderRadius(20)
            }

            Column({ space: 12 }) {
              SectionHeader({ title: '设置与账号', subtitle: this.loading ? '正在同步统计…' : '可以编辑资料、清理缓存或退出当前账号。' })
              this.MenuItem('服务器与资料设置', '修改昵称、手机号、服务器地址', () => AppRouter.push('pages/ProfileSettings', undefined, this))
              this.MenuItem('切换角色工作台', '查看当前身份对应的操作入口', () => AppRouter.push('pages/RoleWorkbench', undefined, this))
              this.MenuItem('清理购物车缓存', '清空本地购物车商品', () => this.clearCache())
              this.MenuItem('关于应用', 'Pawtopia · HarmonyOS API 22', () => AppRouter.push('pages/About', undefined, this))
              this.MenuItem('退出登录', '退出当前账号并回到登录页', () => this.logout(), true)
            }
            .padding(14)
            .backgroundColor(Color.White)
            .border({ width: 1, color: Theme.border })
            .borderRadius(20)
          }
          .padding(16)
          .width('100%')
        }
        .layoutWeight(1)
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }

  @Builder private MenuItem(title: string, desc: string, action: () => void, danger: boolean = false) {
    Row({ space: 12 }) {
      Column()
        .width(8)
        .height(36)
        .borderRadius(4)
        .backgroundColor(danger ? Theme.accentPink : '#CFE2FF')
      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(danger ? '#B03060' : Theme.textPrimary)
        Text(desc)
          .fontSize(12)
          .fontColor(Theme.textSecondary)
      }
      .layoutWeight(1)
      Text('›')
        .fontSize(22)
        .fontColor(danger ? '#B03060' : Theme.textMuted)
    }
    .padding(14)
    .width('100%')
    .backgroundColor('#FCFDFE')
    .border({ width: 1, color: Theme.border })
    .borderRadius(16)
    .onClick(() => action())
  }
}
