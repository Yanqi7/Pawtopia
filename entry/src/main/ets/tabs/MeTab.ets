import { AppRouter } from '../common/AppRouter';
import { SessionStore } from '../store/SessionStore';
import { Api } from '../api/Api';
import { User, AdoptionRequest, Order, Pet, Post } from '../model/Models';
import { AppStatus } from '../app/AppStatus';
import { AppPrompt } from '../common/AppPrompt';
import { Theme } from '../common/Theme';
import { CartStore } from '../store/CartStore';
import { EmptyState, OfflineBanner } from '../components/Ui';

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
      if (!this.user) {
        EmptyState({
          title: '登录后查看你的宠物生活',
          description: '你可以管理宠物档案、领养申请、商城订单和社区内容。',
          actionText: '立即登录',
          action: () => AppRouter.push('pages/Login')
        })
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Column({ space: 14 }) {
              Row({ space: 14 }) {
                Image($r('app.media.people'))
                  .width(72)
                  .height(72)
                  .borderRadius(36)
                Column({ space: 6 }) {
                  Text(this.user?.nickname || this.user?.username || '')
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#18191C')
                  Row({ space: 8 }) {
                    Text(roleLabel(this.user?.role ?? 'USER'))
                      .fontSize(11)
                      .fontColor(Theme.primary)
                      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                      .backgroundColor('#EAF3FF')
                      .borderRadius(12)
                    Text(AppStatus.isBackendOnline() ? '云端已连接' : '本地缓存模式')
                      .fontSize(11)
                      .fontColor('#6B7280')
                      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                      .backgroundColor('#F4F6F8')
                      .borderRadius(12)
                  }
                  Text(this.user?.email || '')
                    .fontSize(12)
                    .fontColor('#61666D')
                }
                .layoutWeight(1)
                Column({ space: 8 }) {
                  Button('消息')
                    .height(34)
                    .padding({ left: 14, right: 14 })
                    .backgroundColor('#F6F7F8')
                    .fontColor('#18191C')
                    .borderRadius(17)
                    .fontSize(12)
                    .onClick(() => AppPrompt.toast('消息中心开发中'))
                }
              }
              .width('100%')

              Row({ space: 10 }) {
                this.StatCard('动态', this.postCount, () => this.navigateTab(0))
                this.StatCard('宠物', this.petCount, () => this.navigateTab(2))
                this.StatCard('订单', this.orderCount, () => AppRouter.push('pages/Orders'))
                this.StatCard('领养', this.adoptionCount, () => AppRouter.push('pages/MyAdoptions'))
              }
              .width('100%')
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(24)

            if (!AppStatus.isBackendOnline()) {
              OfflineBanner({ text: '当前使用本地缓存数据，你仍然可以浏览核心页面。', action: () => this.loadSummary() })
            }

            Column({ space: 12 }) {
              Text('常用服务')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#18191C')
                .width('100%')
              Row({ space: 12 }) {
                this.QuickEntry('我的发布', '查看动态', () => this.navigateTab(0))
                this.QuickEntry('我的宠物', '档案管理', () => this.navigateTab(2))
                this.QuickEntry('商城订单', '购买记录', () => AppRouter.push('pages/Orders'))
                this.QuickEntry('领养申请', '进度跟踪', () => AppRouter.push('pages/MyAdoptions'))
              }
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(24)

            Column({ space: 12 }) {
              this.MenuItem('继续逛商城', '去选购主粮、玩具和护理用品', () => this.navigateTab(3))
              this.MenuItem('切换账号', '返回登录页重新登录', () => AppRouter.push('pages/Login'))
              this.MenuItem('清理购物车缓存', '清空本地购物车商品', () => this.clearCache())
              this.MenuItem('版本信息', this.loading ? '统计同步中…' : '城宠社区 · HarmonyOS 6.0.2 · dev', () => AppPrompt.toast('当前为 dev 分支构建'))
              this.MenuItem('退出登录', '退出当前账号', () => this.logout(), true)
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(24)
          }
          .padding(16)
          .width('100%')
        }
        .layoutWeight(1)
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F6F7F8')
  }

  @Builder private StatCard(label: string, value: number, action: () => void) {
    Column({ space: 4 }) {
      Text(String(value))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#18191C')
      Text(label)
        .fontSize(11)
        .fontColor('#61666D')
    }
    .layoutWeight(1)
    .height(72)
    .backgroundColor('#F6F7F8')
    .borderRadius(18)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => action())
  }

  @Builder private QuickEntry(title: string, desc: string, action: () => void) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#18191C')
      Text(desc)
        .fontSize(11)
        .fontColor('#9499A0')
    }
    .layoutWeight(1)
    .height(78)
    .backgroundColor('#F6F7F8')
    .borderRadius(18)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => action())
  }

  @Builder private MenuItem(title: string, desc: string, action: () => void, danger: boolean = false) {
    Row({ space: 12 }) {
      Column()
        .width(8)
        .height(36)
        .borderRadius(4)
        .backgroundColor(danger ? '#FB7299' : '#CFE2FF')
      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(danger ? '#B03060' : '#18191C')
        Text(desc)
          .fontSize(12)
          .fontColor('#61666D')
      }
      .layoutWeight(1)
      Text('›')
        .fontSize(22)
        .fontColor(danger ? '#B03060' : '#9499A0')
    }
    .padding(16)
    .width('100%')
    .backgroundColor('#FBFBFC')
    .borderRadius(20)
    .onClick(() => action())
  }
}
