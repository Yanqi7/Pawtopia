import { Api } from '../api/Api';
import { AppStatus } from '../app/AppStatus';
import { MediaAssets } from '../assets/MediaAssets';
import { appContext } from '../common/AppContext';
import { AppRouter } from '../common/AppRouter';
import { Theme } from '../common/Theme';
import { CartStore } from '../store/CartStore';
import { SessionStore } from '../store/SessionStore';

@Entry
@Component
struct Index {
  @State private ready: boolean = false;
  @State private errorText: string = '';
  @State private statusText: string = '正在准备应用…';
  @State private online: boolean = true;
  private navigated: boolean = false;

  aboutToAppear(): void {
    if (!this.navigated) {
      this.bootstrap();
    }
  }

  private async bootstrap(): Promise<void> {
    this.navigated = true;
    this.errorText = '';
    this.statusText = '正在恢复会话…';
    try {
      const context = appContext(this);
      await Promise.all([SessionStore.init(context), CartStore.init(context)]);
      this.statusText = '正在检查服务状态…';
      this.online = await Api.probeBackend();
      AppStatus.setBackendOnline(this.online);
      this.statusText = this.online ? '正在进入城宠社区…' : '离线模式已开启';
      this.ready = true;
      if (SessionStore.isLoggedIn() && SessionStore.getToken()) {
        AppRouter.replace('pages/MainTabs');
        return;
      }
      if (this.online) {
        try {
          this.statusText = '正在以演示账号进入…';
          await Api.login('user1', 'user1');
          AppRouter.replace('pages/MainTabs');
          return;
        } catch (e) {
        }
      }
      AppRouter.replace('pages/Login');
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '初始化失败';
      this.navigated = false;
    }
  }

  build() {
    Stack() {
      Image(MediaAssets.heroDog())
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [['#F7FBFFEE', 0], ['#EDF5FFFA', 0.55], ['#F3F7FF', 1]]
        })

      Column({ space: 18 }) {
        Column({ space: 10 }) {
          Image($r('app.media.hero_compose'))
            .width(68)
            .height(68)
          Text('城宠社区')
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.textPrimary)
          Text('社区 · 领养 · 档案 · 商城')
            .fontSize(13)
            .fontColor(Theme.textSecondary)
        }
        .alignItems(HorizontalAlign.Center)

        Column({ space: 10 }) {
          if (this.errorText) {
            Text(this.errorText)
              .fontSize(13)
              .fontColor('#D14343')
              .textAlign(TextAlign.Center)
          } else {
            LoadingProgress()
              .width(28)
              .height(28)
              .color(Theme.primary)
            Text(this.statusText)
              .fontSize(14)
              .fontColor(Theme.textSecondary)
              .textAlign(TextAlign.Center)
            Text(this.online ? '服务连接正常' : '当前将使用本地缓存数据')
              .fontSize(12)
              .fontColor(this.online ? Theme.success : Theme.secondary)
          }
        }
        .width('100%')
        .padding(18)
        .backgroundColor('#FFFFFFE6')
        .borderRadius(24)
      }
      .padding({ left: 24, right: 24, top: 32, bottom: 32 })
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.background)
  }
}
