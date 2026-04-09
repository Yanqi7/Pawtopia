import { Api } from '../api/Api';
import { AppConfig } from '../app/AppConfig';
import { MediaAssets } from '../assets/MediaAssets';
import { appContext } from '../common/AppContext';
import { AppRouter } from '../common/AppRouter';
import { Theme } from '../common/Theme';
import { SessionStore } from '../store/SessionStore';

@Entry
@Component
struct Register {
  @State private username: string = '';
  @State private password: string = '';
  @State private confirmPassword: string = '';
  @State private email: string = '';
  @State private nickname: string = '';
  @State private baseUrl: string = AppConfig.DEFAULT_BASE_URL;
  @State private loading: boolean = false;
  @State private errorText: string = '';

  aboutToAppear(): void {
    this.prepare();
  }

  private async prepare(): Promise<void> {
    await SessionStore.init(appContext(this));
    this.baseUrl = await SessionStore.getBaseUrl();
  }

  private async doRegister(): Promise<void> {
    if (!this.username.trim() || !this.email.trim() || !this.password) {
      this.errorText = '请完整填写用户名、邮箱和密码';
      return;
    }
    if (this.password.length < 6) {
      this.errorText = '密码至少 6 位';
      return;
    }
    if (this.password !== this.confirmPassword) {
      this.errorText = '两次输入的密码不一致';
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      await SessionStore.setBaseUrl(this.baseUrl.trim() || AppConfig.DEFAULT_BASE_URL);
      await Api.register(this.username.trim(), this.password, this.email.trim(), this.nickname.trim(), 'USER');
      AppRouter.replace('pages/MainTabs');
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '注册失败';
    } finally {
      this.loading = false;
    }
  }

  build() {
    Stack() {
      Image(MediaAssets.heroCat())
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(0.1)

      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [['#FFF9FB', 0], ['#F5F8FF', 0.6], ['#F7F8FC', 1]]
        })

      Scroll() {
        Column({ space: 18 }) {
          Row({ space: 12 }) {
            Image($r('app.media.hero_back'))
              .width(24)
              .height(24)
              .onClick(() => AppRouter.back())
            Column({ space: 4 }) {
              Text('创建你的城宠社区账号')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.textPrimary)
              Text('普通用户注册后即可进入社区、领养、档案和商城。')
                .fontSize(12)
                .fontColor(Theme.textSecondary)
            }
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)

          Column({ space: 14 }) {
            TextInput({ placeholder: '用户名', text: this.username })
              .height(48)
              .backgroundColor('#FFFFFFE8')
              .border({ width: 1, color: Theme.border })
              .borderRadius(14)
              .padding({ left: 14, right: 14 })
              .onChange((value: string) => this.username = value)

            TextInput({ placeholder: '昵称（可选）', text: this.nickname })
              .height(48)
              .backgroundColor('#FFFFFFE8')
              .border({ width: 1, color: Theme.border })
              .borderRadius(14)
              .padding({ left: 14, right: 14 })
              .onChange((value: string) => this.nickname = value)

            TextInput({ placeholder: '邮箱', text: this.email })
              .height(48)
              .backgroundColor('#FFFFFFE8')
              .border({ width: 1, color: Theme.border })
              .borderRadius(14)
              .padding({ left: 14, right: 14 })
              .onChange((value: string) => this.email = value)

            TextInput({ placeholder: '密码', text: this.password })
              .height(48)
              .type(InputType.Password)
              .backgroundColor('#FFFFFFE8')
              .border({ width: 1, color: Theme.border })
              .borderRadius(14)
              .padding({ left: 14, right: 14 })
              .onChange((value: string) => this.password = value)

            TextInput({ placeholder: '确认密码', text: this.confirmPassword })
              .height(48)
              .type(InputType.Password)
              .backgroundColor('#FFFFFFE8')
              .border({ width: 1, color: Theme.border })
              .borderRadius(14)
              .padding({ left: 14, right: 14 })
              .onChange((value: string) => this.confirmPassword = value)

            TextInput({ placeholder: '服务器地址', text: this.baseUrl })
              .height(48)
              .backgroundColor('#FFFFFFE8')
              .border({ width: 1, color: Theme.border })
              .borderRadius(14)
              .padding({ left: 14, right: 14 })
              .onChange((value: string) => this.baseUrl = value)

            Row({ space: 8 }) {
              Image($r('app.media.hero_bell'))
                .width(18)
                .height(18)
              Text('商家、宠物医院、管理员账号需由后台开通。')
                .fontSize(12)
                .fontColor(Theme.textSecondary)
                .layoutWeight(1)
            }
            .padding(12)
            .backgroundColor('#FFF5EC')
            .borderRadius(14)

            if (this.errorText) {
              Text(this.errorText)
                .fontSize(12)
                .fontColor('#D14343')
                .width('100%')
            }

            Button(this.loading ? '注册中…' : '完成注册')
              .width('100%')
              .height(50)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .borderRadius(16)
              .linearGradient({
                angle: 90,
                colors: [[Theme.accent, 0], ['#FFAE7D', 1]]
              })
              .enabled(!this.loading)
              .onClick(() => this.doRegister())

            Row() {
              Text('已有账号？')
                .fontSize(13)
                .fontColor(Theme.textSecondary)
              Text('返回登录')
                .fontSize(13)
                .fontColor(Theme.primary)
                .fontWeight(FontWeight.Medium)
                .onClick(() => AppRouter.back())
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .padding(18)
          .backgroundColor('#FFFFFFD9')
          .borderRadius(24)
        }
        .padding({ left: 20, right: 20, top: 20, bottom: 24 })
        .width('100%')
      }
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.background)
  }
}
