import { AppRouter } from '../common/AppRouter';
import { SessionStore } from '../store/SessionStore';
import { Api } from '../api/Api';
import { User, AdoptionRequest, Order, Pet, Post } from '../model/Models';
import { AppStatus } from '../app/AppStatus';
import { AppPrompt } from '../common/AppPrompt';
import { Theme } from '../common/Theme';
import { CartStore } from '../store/CartStore';

function roleLabel(role: string): string {
  return role === 'PET_SHOP' ? '宠物店' : role === 'PET_HOSPITAL' ? '宠物医院' : role === 'SELLER' ? '卖家' : role === 'ADMIN' ? '管理员' : '普通用户';
}

interface MainTabParams {
  tab?: number;
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
    this.user = SessionStore.getUser();
    this.loadSummary();
  }

  private async loadSummary(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      this.postCount = 0;
      this.petCount = 0;
      this.orderCount = 0;
      this.adoptionCount = 0;
      return;
    }
    this.loading = true;
    try {
      const userId = user.id;
      const result = await Promise.all([
        Api.getUserPosts(userId),
        Api.getMyPets(userId),
        Api.getMyOrders(userId),
        Api.getMyAdoptionRequests()
      ]);
      const posts = result[0] as Post[];
      const pets = result[1] as Pet[];
      const orders = result[2] as Order[];
      const adoptions = result[3] as AdoptionRequest[];
      this.postCount = posts.length;
      this.petCount = pets.length;
      this.orderCount = orders.length;
      this.adoptionCount = adoptions.length;
    } catch (e) {
    } finally {
      this.loading = false;
    }
  }

  private async logout(): Promise<void> {
    await SessionStore.logout();
    AppRouter.replace('pages/Login');
  }

  private async clearCache(): Promise<void> {
    await CartStore.clear();
    AppPrompt.toast('购物车缓存已清空');
  }

  private navigateTab(tab: number): void {
    AppRouter.replace('pages/MainTabs', { tab: tab } as MainTabParams);
  }

  build() {
    Column() {
      if (this.user) {
        Column({ space: 14 }) {
          Row({ space: 14 }) {
            Image($r('app.media.people'))
              .width(72)
              .height(72)
              .borderRadius(36)

            Column({ space: 6 }) {
              Text(this.user?.nickname || this.user?.username || '')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text(roleLabel(this.user?.role ?? 'USER'))
                .fontSize(12)
                .fontColor('#EAF2FF')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor('#FFFFFF22')
                .borderRadius(12)
              Text(this.user?.email || '')
                .fontSize(12)
                .fontColor('#F8FAFC')
              Text(AppStatus.isBackendOnline() ? '云端已连接' : '当前离线模式')
                .fontSize(12)
                .fontColor('#F8FAFC')
            }
            .layoutWeight(1)
          }
          .width('100%')

          Row({ space: 12 }) {
            this.StatCard('帖子', this.postCount, () => this.navigateTab(0))
            this.StatCard('宠物', this.petCount, () => this.navigateTab(2))
            this.StatCard('订单', this.orderCount, () => AppRouter.push('pages/Orders'))
            this.StatCard('领养', this.adoptionCount, () => AppRouter.push('pages/MyAdoptions'))
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 20, bottom: 18 })
        .linearGradient({ angle: 135, colors: [['#3B9AFF', 0], ['#2B7FFF', 1]] })

        Scroll() {
          Column({ space: 12 }) {
            this.MenuItem('我的发布', `${this.postCount}`, $r('app.media.tiezi'), () => this.navigateTab(0))
            this.MenuItem('我的宠物', `${this.petCount}`, $r('app.media.dangan'), () => this.navigateTab(2))
            this.MenuItem('我的订单', `${this.orderCount}`, $r('app.media.shopping'), () => AppRouter.push('pages/Orders'))
            this.MenuItem('我的领养申请', `${this.adoptionCount}`, $r('app.media.like'), () => AppRouter.push('pages/MyAdoptions'))
            this.MenuItem('继续逛商城', '精选好物', $r('app.media.gouwuche'), () => this.navigateTab(3))
            this.MenuItem('切换账号', '', $r('app.media.ic_switch'), () => AppRouter.push('pages/Login'))
            this.MenuItem('关于 Pawtopia', '宠物社区 · 领养 · 档案 · 商城', $r('app.media.more'), () => AppPrompt.toast('Pawtopia 正在持续完善中'))
            this.MenuItem('清理缓存', '清空购物车缓存', $r('app.media.ic_trash'), () => this.clearCache())
            this.MenuItem('版本信息', this.loading ? '同步中…' : 'HarmonyOS 6.0.2 / dev', $r('app.media.more'), () => AppPrompt.toast('当前为 dev 分支最新构建'))
            this.MenuItem('退出登录', '', $r('app.media.ic_logout'), () => this.logout(), true)
          }
          .width('100%')
          .padding(16)
        }
        .layoutWeight(1)
      } else {
        Column({ space: 14 }) {
          Text('登录后体验完整的宠物社区')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.textPrimary)
          Text('你可以发布宠物动态、维护档案、提交领养申请和管理订单。')
            .fontSize(13)
            .fontColor(Theme.textSecondary)
            .textAlign(TextAlign.Center)
          Button('立即登录')
            .width('70%')
            .height(46)
            .backgroundColor(Theme.primary)
            .fontColor(Color.White)
            .borderRadius(23)
            .onClick(() => AppRouter.push('pages/Login'))
        }
        .height('100%')
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }

  @Builder private StatCard(label: string, value: number, action: () => void) {
    Column({ space: 4 }) {
      Text(String(value))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
      Text(label)
        .fontSize(11)
        .fontColor('#EAF2FF')
    }
    .layoutWeight(1)
    .height(72)
    .backgroundColor('#FFFFFF1A')
    .borderRadius(18)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => action())
  }

  @Builder private MenuItem(title: string, desc: string, icon: Resource, action: () => void, danger: boolean = false) {
    Row({ space: 12 }) {
      Image(icon)
        .width(22)
        .height(22)
        .fillColor(danger ? '#FF5A5F' : Theme.primary)
      Column({ space: 4 }) {
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(danger ? '#FF5A5F' : Theme.textPrimary)
        if (desc) {
          Text(desc)
            .fontSize(12)
            .fontColor(Theme.textSecondary)
        }
      }
      .layoutWeight(1)
      Text('›')
        .fontSize(22)
        .fontColor(danger ? '#FF5A5F' : Theme.textMuted)
    }
    .padding(16)
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(20)
    .onClick(() => action())
  }
}
