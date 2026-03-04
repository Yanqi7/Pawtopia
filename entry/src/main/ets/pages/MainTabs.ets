import { SessionStore } from '../store/SessionStore';
import { CartStore } from '../store/CartStore';
import { CommunityTab } from '../tabs/CommunityTab';
import { AdoptTab } from '../tabs/AdoptTab';
import { MedicalTab } from '../tabs/MedicalTab';
import { MallTab } from '../tabs/MallTab';
import { MeTab } from '../tabs/MeTab';

@Entry
@Component
struct MainTabs {
  @State private ready: boolean = false;

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
          Text('加载中').fontSize(14).fontColor('#666')
        }
        .height('100%')
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      if (this.ready) {
        Tabs({ barPosition: BarPosition.End }) {
          TabContent() {
            CommunityTab()
          }.tabBar('社区')

          TabContent() {
            AdoptTab()
          }.tabBar('领养')

          TabContent() {
            MedicalTab()
          }.tabBar('医疗')

          TabContent() {
            MallTab()
          }.tabBar('商城')

          TabContent() {
            MeTab()
          }.tabBar('我的')
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
  }
}
