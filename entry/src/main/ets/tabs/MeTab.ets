import { AppRouter } from '../common/AppRouter';
import { SessionStore } from '../store/SessionStore';
import { Api } from '../api/Api';
import { User, AdoptionRequest, Order, Pet, Post, UserRole } from '../model/Models';
import { AppStatus } from '../app/AppStatus';
import { AppPrompt } from '../common/AppPrompt';
import { Theme } from '../common/Theme';
import { CartStore } from '../store/CartStore';
import { EmptyState, OfflineBanner, StatsRow, UserHeader } from '../components/Ui';

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

interface MenuEntry {
  title: string;
  desc: string;
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

  private menuEntries(): MenuEntry[] {
    return [
      { title: '资料设置', desc: '' },
      { title: '我的发布', desc: '' },
      { title: '订单中心', desc: '' },
      { title: '领养申请', desc: '' }
    ];
  }

  private roleEntries(): MenuEntry[] {
    if (this.role() === 'SELLER') {
      return [
        { title: '我的商品', desc: '管理商品' },
        { title: '上新商品', desc: '新增商品' },
        { title: '订单履约', desc: '处理订单' }
      ];
    }
    if (this.role() === 'PET_HOSPITAL') {
      return [
        { title: '档案工作台', desc: '查看授权宠物' },
        { title: '角色入口', desc: '查看工作台' }
      ];
    }
    if (this.role() === 'PET_SHOP') {
      return [
        { title: '领养发布', desc: '管理领养宠物' },
        { title: '店铺工作台', desc: '查看当前入口' }
      ];
    }
    if (this.role() === 'ADMIN') {
      return [
        { title: '用户管理', desc: '管理账号' },
        { title: '内容巡检', desc: '管理帖子' },
        { title: '商品管理', desc: '维护商品' },
        { title: '宠物档案管理', desc: '编辑宠物档案' },
        { title: '领养信息管理', desc: '管理领养信息' },
        { title: '系统订单', desc: '查看全量订单' }
      ];
    }
    return [];
  }

  private onMenuClick(title: string): void {
    if (title === '资料设置') {
      AppRouter.push('pages/ProfileSettings', undefined, this);
      return;
    }
    if (title === '我的发布') {
      this.navigateTab(0, { communityMode: 'MINE' });
      return;
    }
    if (title === '订单中心') {
      AppRouter.push('pages/Orders', undefined, this);
      return;
    }
    if (title === '领养申请') {
      this.openAdoptionCenter();
      return;
    }
    if (title === '我的商品') {
      AppRouter.push('pages/SellerProducts', undefined, this);
      return;
    }
    if (title === '上新商品') {
      AppRouter.push('pages/NewProduct', undefined, this);
      return;
    }
    if (title === '订单履约') {
      AppRouter.push('pages/Orders', undefined, this);
      return;
    }
    if (title === '档案工作台') {
      this.navigateTab(2);
      return;
    }
    if (title === '角色入口' || title === '店铺工作台' || title === '切换角色工作台') {
      AppRouter.push('pages/RoleWorkbench', undefined, this);
      return;
    }
    if (title === '领养发布') {
      this.navigateTab(1, { adoptFilter: 'MINE' });
      return;
    }
    if (title === '用户管理') {
      AppRouter.push('pages/AdminUsers', undefined, this);
      return;
    }
    if (title === '内容巡检') {
      AppRouter.push('pages/AdminContent', undefined, this);
      return;
    }
    if (title === '商品管理') {
      AppRouter.push('pages/SellerProducts', undefined, this);
      return;
    }
    if (title === '宠物档案管理') {
      AppRouter.push('pages/AdminPets', { mode: 'PROFILE' } as AdminPetsParams, this);
      return;
    }
    if (title === '领养信息管理') {
      AppRouter.push('pages/AdminPets', { mode: 'ADOPT' } as AdminPetsParams, this);
      return;
    }
    if (title === '系统订单') {
      AppRouter.push('pages/Orders', undefined, this);
      return;
    }
    if (title === '清理购物车缓存') {
      this.clearCache();
      return;
    }
    if (title === '关于应用') {
      AppRouter.push('pages/About', undefined, this);
      return;
    }
    if (title === '退出登录') {
      this.logout();
    }
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

            Column({ space: 10 }) {
              ForEach(this.menuEntries(), (item: MenuEntry) => {
                this.MenuItem(item.title, item.desc, () => this.onMenuClick(item.title))
              }, (item: MenuEntry) => item.title)
            }
            .padding(14)
            .backgroundColor(Color.White)
            .border({ width: 1, color: Theme.border })
            .borderRadius(20)

            if (this.roleEntries().length > 0) {
              Column({ space: 10 }) {
                ForEach(this.roleEntries(), (item: MenuEntry) => {
                  this.MenuItem(item.title, item.desc, () => this.onMenuClick(item.title))
                }, (item: MenuEntry) => item.title)
              }
              .padding(14)
              .backgroundColor(Color.White)
              .border({ width: 1, color: Theme.border })
              .borderRadius(20)
            }

            Column({ space: 10 }) {
              this.MenuItem('切换角色工作台', '', () => this.onMenuClick('切换角色工作台'))
              this.MenuItem('清理购物车缓存', '', () => this.onMenuClick('清理购物车缓存'))
              this.MenuItem('关于应用', '', () => this.onMenuClick('关于应用'))
              this.MenuItem('退出登录', '', () => this.onMenuClick('退出登录'), true)
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
        if (desc) {
          Text(desc)
            .fontSize(12)
            .fontColor(Theme.textSecondary)
        }
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
