import { SessionStore } from '../store/SessionStore';
import { CartStore } from '../store/CartStore';
import { CommunityTab } from '../tabs/CommunityTab';
import { AdoptTab } from '../tabs/AdoptTab';
import { PetProfileTab } from '../tabs/PetProfileTab';
import { MallTab } from '../tabs/MallTab';
import { MeTab } from '../tabs/MeTab';
import { appContext } from '../common/AppContext';
import { Theme } from '../common/Theme';
import { AppRouter } from '../common/AppRouter';

interface MainTabParams {
  tab?: number;
}

@Entry
@Component
struct MainTabs {
  @State private ready: boolean = false;
  @State private currentTabIndex: number = 0;

  aboutToAppear(): void {
    const params = AppRouter.params<MainTabParams>();
    this.currentTabIndex = Math.max(0, Math.min(4, Number(params?.tab ?? this.currentTabIndex)));
    const context = appContext(this);
    Promise.all([SessionStore.init(context), CartStore.init(context)]).then(() => {
      this.ready = true;
    });
  }

  build() {
    Stack() {
      if (!this.ready) {
        Column({ space: 10 }) {
          LoadingProgress()
            .width(28)
            .height(28)
            .color(Theme.primary)
          Text('加载中…')
            .fontSize(14)
            .fontColor(Theme.textSecondary)
        }
        .height('100%')
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(Theme.background)
      }

      if (this.ready) {
        Tabs({ barPosition: BarPosition.End, index: this.currentTabIndex }) {
          TabContent() {
            CommunityTab()
          }
          .tabBar(this.TabBarBuilder(0, 'home', '社区'))

          TabContent() {
            AdoptTab()
          }
          .tabBar(this.TabBarBuilder(1, 'like', '领养'))

          TabContent() {
            PetProfileTab()
          }
          .tabBar(this.TabBarBuilder(2, 'dangan', '档案'))

          TabContent() {
            MallTab()
          }
          .tabBar(this.TabBarBuilder(3, 'shopping', '商城'))

          TabContent() {
            MeTab()
          }
          .tabBar(this.TabBarBuilder(4, 'wode', '我的'))
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Theme.surface)
        .barBackgroundColor('#FFFFFFF5')
        .divider({ strokeWidth: 1, color: Theme.border })
        .scrollable(false)
        .onChange((index: number) => {
          this.currentTabIndex = index;
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder TabBarBuilder(index: number, icon: string, label: string) {
    Column({ space: 4 }) {
      Image($r(`app.media.${icon}`))
        .width(22)
        .height(22)
        .fillColor(this.currentTabIndex === index ? Theme.primary : Theme.textMuted)
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTabIndex === index ? Theme.primary : Theme.textMuted)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 8, bottom: 8 })
  }
}
