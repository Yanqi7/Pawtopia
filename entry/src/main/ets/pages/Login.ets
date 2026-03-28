import router from '@ohos.router';
import { Api } from '../api/Api';
import promptAction from '@ohos.promptAction';
import { AppConfig } from '../app/AppConfig';
import { PreferencesStore } from '../store/PreferencesStore';
import { SessionStore } from '../store/SessionStore';
import { UserRole } from '../model/Models';

@Entry
@Component
struct Login {
  @State private username: string = '';
  @State private password: string = '';
  @State private selectedRole: UserRole = 'USER';
  @State private showPassword: boolean = false;
  @State private loading: boolean = false;
  @State private errorText: string = '';

  aboutToAppear(): void {
    const context = getContext(this);
    PreferencesStore.init(context);
  }

  private async doLogin(): Promise<void> {
    if (!this.username || !this.password) {
      this.errorText = '请输入用户名和密码';
      return;
    }
    this.errorText = '';
    this.loading = true;
    try {
      await Api.login(this.username.trim(), this.password);
      router.replaceUrl({ url: 'pages/MainTabs' });
    } catch (e) {
      this.errorText = (e as Error).message || '登录失败';
    } finally {
      this.loading = false;
    }
  }

  build() {
    Stack() {
      // Gradient background
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [['#F0E8FF', 0.0], ['#E8F4FF', 0.5], ['#F0FFF8', 1.0]]
        })

      Scroll() {
        Column({ space: 20 }) {
          // Top spacing
          Blank().height(30)

          // APP Logo and title
          Column({ space: 8 }) {
            Row() {
              Blank()
              Text('APP')
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor('#5B7FFF')
              Image($r('app.media.dog'))
                .width(50)
                .height(50)
                .margin({ left: 8 })
              Blank()
            }
          }.width('100%')

          // Account input
          Column({ space: 2 }) {
            Text('账号').fontSize(13).fontColor('#666')
            Row({ space: 8 }) {
              Image($r('app.media.ic_people')).width(20).height(20)
              TextInput({ placeholder: '请输入账号/手机号', text: this.username })
                .layoutWeight(1)
                .onChange((v: string) => this.username = v)
              if (this.username) {
                Text('清除').fontSize(12).fontColor('#2B7FFF').onClick(() => this.username = '')
              }
            }
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .borderRadius(8)
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#E0E0E0' })
          }
          .width('100%')

          // Password input
          Column({ space: 2 }) {
            Text('密码').fontSize(13).fontColor('#666')
            Row({ space: 8 }) {
              Image($r('app.media.lock')).width(20).height(20)
              TextInput({ placeholder: '请输入密码', text: this.password, type: this.showPassword ? InputType.Normal : InputType.Password })
                .layoutWeight(1)
                .onChange((v: string) => this.password = v)
              Text(this.showPassword ? '隐藏' : '显示')
                .fontSize(12)
                .fontColor('#2B7FFF')
                .onClick(() => this.showPassword = !this.showPassword)
            }
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .borderRadius(8)
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#E0E0E0' })
          }
          .width('100%')

          // Forgot password link
          Row() {
            Blank()
            Text('忘记密码？')
              .fontSize(12)
              .fontColor('#2B7FFF')
          }.width('100%')

          // Role selection buttons
          Column({ space: 2 }) {
            Text('身份选择').fontSize(13).fontColor('#666')
            Row({ space: 10 }) {
              this.RoleButton('用户', 'USER')
              this.RoleButton('商家', 'SELLER')
              this.RoleButton('医生', 'PET_HOSPITAL')
            }.width('100%')
          }

          // Error message
          if (this.errorText) {
            Text(this.errorText)
              .fontSize(12)
              .fontColor(Color.Red)
              .width('100%')
              .textAlign(TextAlign.Center)
          }

          // Login button (orange gradient)
          Button(this.loading ? '登录中…' : '登 录')
            .width('100%')
            .height(48)
            .fontWeight(FontWeight.Medium)
            .fontSize(16)
            .borderRadius(24)
            .linearGradient({
              angle: 90,
              colors: [['#FF9D4E', 0.0], ['#FFB347', 1.0]]
            })
            .fontColor(Color.White)
            .enabled(!this.loading)
            .onClick(() => this.doLogin())

          // Register link
          Row({ space: 4 }) {
            Text('没有账号？')
              .fontSize(13)
              .fontColor('#666')
            Text('去注册')
              .fontSize(13)
              .fontColor('#2B7FFF')
              .fontWeight(FontWeight.Medium)
              .onClick(() => router.pushUrl({ url: 'pages/Register' }))
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)

          Blank()
        }
        .padding({ left: 20, right: 20, top: 0, bottom: 30 })
        .width('100%')
      }
      .height('100%')
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder RoleButton(label: string, role: UserRole) {
    Button(label)
      .layoutWeight(1)
      .height(40)
      .fontSize(13)
      .backgroundColor(this.selectedRole === role ? '#FF9D4E' : '#FFFFFF')
      .fontColor(this.selectedRole === role ? Color.White : '#666')
      .border({ width: 1, color: this.selectedRole === role ? '#FF9D4E' : '#E0E0E0' })
      .onClick(() => this.selectedRole = role)
  }
}
