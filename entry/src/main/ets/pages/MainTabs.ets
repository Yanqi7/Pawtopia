import { SessionStore } from '../store/SessionStore';
import { CartStore } from '../store/CartStore';
import { CommunityTab } from '../tabs/CommunityTab';
import { AdoptTab } from '../tabs/AdoptTab';
import { PetProfileTab } from '../tabs/PetProfileTab';
import { MallTab } from '../tabs/MallTab';
import { MeTab } from '../tabs/MeTab';

@Entry
@Component
struct MainTabs {
  @State private ready: boolean = false;
  @State private currentTabIndex: number = 0;

  aboutToAppear(): void {
    const context = getContext(this);
    Promise.all([SessionStore.init(context), CartStore.init(context)]).then(() => {
      this.ready = true;
    });
  }

  build() {
    Stack() {
      if (!this.ready) {
        Column() {
          Text('加载中…')
            .fontSize(14)
            .fontColor('#666666')
        }
        .height('100%')
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      if (this.ready) {
        Tabs({ barPosition: BarPosition.End, index: this.currentTabIndex }) {
          TabContent() {
            CommunityTab()
          }
          .tabBar(this.TabBarBuilder(0, 'home.png', '社区'))

          TabContent() {
            AdoptTab()
          }
          .tabBar(this.TabBarBuilder(1, 'like.png', '领养'))

          TabContent() {
            PetProfileTab()
          }
          .tabBar(this.TabBarBuilder(2, 'dangan.png', '档案'))

          TabContent() {
            MallTab()
          }
          .tabBar(this.TabBarBuilder(3, 'shopping.png', '商城'))

          TabContent() {
            MeTab()
          }
          .tabBar(this.TabBarBuilder(4, 'wode.png', '我的'))
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')
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
        .width(24)
        .height(24)
        .fillColor(this.currentTabIndex === index ? '#2B7FFF' : '#999999')
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTabIndex === index ? '#2B7FFF' : '#999999')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 8, bottom: 8 })
  }
}
