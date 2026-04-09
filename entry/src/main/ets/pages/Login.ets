import { Api } from '../api/Api';
import { AppConfig } from '../app/AppConfig';
import { MediaAssets } from '../assets/MediaAssets';
import { appContext } from '../common/AppContext';
import { AppPrompt } from '../common/AppPrompt';
import { AppRouter } from '../common/AppRouter';
import { Theme } from '../common/Theme';
import { SessionStore } from '../store/SessionStore';

@Entry
@Component
struct Login {
  @State private username: string = '';
  @State private password: string = '';
  @State private baseUrl: string = AppConfig.DEFAULT_BASE_URL;
  @State private loading: boolean = false;
  @State private passwordVisible: boolean = false;
  @State private errorText: string = '';
  @State private online: boolean = true;

  aboutToAppear(): void {
    this.prepare();
  }

  private async prepare(): Promise<void> {
    try {
      await SessionStore.init(appContext(this));
      this.baseUrl = await SessionStore.getBaseUrl();
      this.online = await Api.probeBackend();
    } catch (e) {
      this.online = false;
    }
  }

  private async saveBaseUrl(showToast: boolean): Promise<void> {
    const nextBaseUrl = this.baseUrl.trim() || AppConfig.DEFAULT_BASE_URL;
    this.baseUrl = nextBaseUrl;
    await SessionStore.setBaseUrl(nextBaseUrl);
    this.online = await Api.probeBackend();
    if (showToast) {
      AppPrompt.toast('服务器地址已保存');
    }
  }

  private async doLogin(): Promise<void> {
    if (!this.username.trim() || !this.password) {
      this.errorText = '请输入用户名和密码';
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      await this.saveBaseUrl(false);
      await Api.login(this.username.trim(), this.password);
      AppRouter.replace('pages/MainTabs');
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '登录失败';
    } finally {
      this.loading = false;
    }
  }

  private async resetBaseUrl(): Promise<void> {
    this.baseUrl = AppConfig.DEFAULT_BASE_URL;
    await this.saveBaseUrl(true);
  }

  build() {
    Stack() {
      Image(MediaAssets.loginBackground())
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(0.18)

      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [['#F9FCFF', 0], ['#F2F7FF', 0.55], ['#F7F8FC', 1]]
        })

      Scroll() {
        Column({ space: 18 }) {
          Blank().height(10)

          Stack({ alignContent: Alignment.BottomEnd }) {
            Image(MediaAssets.heroDog())
              .width('100%')
              .height(220)
              .borderRadius(30)
              .objectFit(ImageFit.Cover)
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                Image($r('app.media.hero_bell'))
                  .width(24)
                  .height(24)
                Text(this.online ? '服务在线' : '离线模式')
                  .fontSize(12)
                  .fontColor(this.online ? Theme.success : Theme.secondary)
              }
              Text('和毛孩子一起，认真记录每一天')
                .fontSize(26)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .maxLines(2)
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#0F172A66')
            .borderRadius(30)
          }

          Column({ space: 14 }) {
            Row({ space: 8 }) {
              Image($r('app.media.hero_search'))
                .width(20)
                .height(20)
              Text('连接服务器')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.textPrimary)
            }
            TextInput({ placeholder: AppConfig.DEFAULT_BASE_URL, text: this.baseUrl })
              .height(46)
              .backgroundColor('#F8FAFF')
              .border({ width: 1, color: Theme.border })
              .borderRadius(14)
              .padding({ left: 14, right: 14 })
              .fontSize(14)
              .onChange((value: string) => this.baseUrl = value)

            Row({ space: 10 }) {
              Button('保存地址')
                .height(34)
                .backgroundColor('#E8F1FF')
                .fontColor(Theme.primary)
                .borderRadius(17)
                .onClick(() => this.saveBaseUrl(true))
              Button('恢复默认')
                .height(34)
                .backgroundColor('#FFF1E7')
                .fontColor(Theme.secondary)
                .borderRadius(17)
                .onClick(() => this.resetBaseUrl())
              Blank()
            }

            Text('普通用户可直接注册；商家、宠物医院账号由管理员开通。')
              .fontSize(12)
              .fontColor(Theme.textSecondary)
          }
          .width('100%')
          .padding(18)
          .backgroundColor('#FFFFFFEE')
          .borderRadius(24)

          Column({ space: 14 }) {
            Text('账号登录')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.textPrimary)
              .width('100%')

            TextInput({ placeholder: '请输入用户名', text: this.username })
              .height(48)
              .backgroundColor('#F8FAFF')
              .border({ width: 1, color: Theme.border })
              .borderRadius(14)
              .padding({ left: 14, right: 14 })
              .fontSize(14)
              .onChange((value: string) => this.username = value)

            Row({ space: 10 }) {
              TextInput({ placeholder: '请输入密码', text: this.password })
                .layoutWeight(1)
                .height(48)
                .backgroundColor('#F8FAFF')
                .border({ width: 1, color: Theme.border })
                .borderRadius(14)
                .padding({ left: 14, right: 14 })
                .fontSize(14)
                .type(this.passwordVisible ? InputType.Normal : InputType.Password)
                .onChange((value: string) => this.password = value)
              Button(this.passwordVisible ? '隐藏' : '显示')
                .height(48)
                .padding({ left: 16, right: 16 })
                .backgroundColor('#EEF2FF')
                .fontColor(Theme.primary)
                .borderRadius(14)
                .onClick(() => this.passwordVisible = !this.passwordVisible)
            }

            if (this.errorText) {
              Text(this.errorText)
                .fontSize(12)
                .fontColor('#D14343')
                .width('100%')
            }

            Button(this.loading ? '登录中…' : '登录城宠社区')
              .width('100%')
              .height(50)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .borderRadius(16)
              .linearGradient({
                angle: 90,
                colors: [[Theme.primary, 0], ['#5CA8FF', 1]]
              })
              .enabled(!this.loading)
              .onClick(() => this.doLogin())

            Row() {
              Text('还没有账号？')
                .fontSize(13)
                .fontColor(Theme.textSecondary)
              Text('立即注册')
                .fontSize(13)
                .fontColor(Theme.primary)
                .fontWeight(FontWeight.Medium)
                .onClick(() => AppRouter.push('pages/Register'))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .padding(18)
          .backgroundColor('#FFFFFFEE')
          .borderRadius(24)
        }
        .padding({ left: 20, right: 20, top: 18, bottom: 24 })
        .width('100%')
      }
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.background)
  }
}
