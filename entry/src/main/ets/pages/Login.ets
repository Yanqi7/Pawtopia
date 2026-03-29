import router from '@ohos.router';
import { Api } from '../api/Api';
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
    Column() {
      Scroll() {
        Column({ space: 20 }) {
          Blank().height(30)

          // Logo and title
          Row() {
            Blank()
            Column({ space: 8 }) {
              Text('城宠社区')
                .fontSize(32)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2B7FFF')
                .textAlign(TextAlign.Center)
              Stack() {
                Circle()
                  .width(80)
                  .height(80)
                  .fill('#B3D9FF')
                Image($r('app.media.dog'))
                  .width(76)
                  .height(76)
                  .borderRadius(38)
                  .objectFit(ImageFit.Cover)
              }
            }
            .alignItems(HorizontalAlign.Center)
            Blank()
          }
          .width('100%')

          // Username input
          Column({ space: 6 }) {
            Text('账号/手机号')
              .fontSize(12)
              .fontColor('#666666')
            TextInput({ placeholder: '请输入账号或手机号', text: this.username })
              .width('100%')
              .height(40)
              .padding({ left: 12, right: 12 })
              .borderRadius(8)
              .backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#E8E8E8' })
              .fontSize(14)
              .onChange((v: string) => this.username = v)
          }
          .width('100%')

          // Password input
          Column({ space: 6 }) {
            Text('密码')
              .fontSize(12)
              .fontColor('#666666')
            TextInput({ placeholder: '请输入密码', text: this.password })
              .width('100%')
              .height(40)
              .padding({ left: 12, right: 12 })
              .borderRadius(8)
              .backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#E8E8E8' })
              .type(InputType.Password)
              .fontSize(14)
              .onChange((v: string) => this.password = v)
          }
          .width('100%')

          // Register and forgot password
          Row({ space: 12 }) {
            Button('注册')
              .layoutWeight(1)
              .height(36)
              .fontSize(14)
              .type(ButtonType.Normal)
              .backgroundColor('#2B7FFF')
              .fontColor(Color.White)
              .borderRadius(6)
              .onClick(() => router.pushUrl({ url: 'pages/Register' }))

            Button('忘记密码?')
              .layoutWeight(1)
              .height(36)
              .fontSize(14)
              .type(ButtonType.Normal)
              .backgroundColor('#2B7FFF')
              .fontColor(Color.White)
              .borderRadius(6)
          }

          // Identity selection
          Column({ space: 8 }) {
            Text('选择身份')
              .fontSize(12)
              .fontColor('#666666')
              .fontWeight(FontWeight.Medium)

            this.RoleSelectionRow()
          }

          // Error message
          if (this.errorText) {
            Text(this.errorText)
              .fontSize(12)
              .fontColor('#ff4d4f')
              .width('100%')
              .textAlign(TextAlign.Center)
          }

          // Login button
          Button(this.loading ? '登录中…' : '登  录')
            .width('100%')
            .height(44)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .type(ButtonType.Capsule)
            .backgroundColor('#2B7FFF')
            .fontColor(Color.White)
            .enabled(!this.loading)
            .onClick(() => this.doLogin())

          Blank()
        }
        .padding({ left: 20, right: 20, top: 12, bottom: 30 })
        .width('100%')
      }
      .height('100%')
      .width('100%')
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder RoleSelectionRow() {
    Row({ space: 12 }) {
      Button('用户')
        .layoutWeight(1)
        .height(36)
        .fontSize(13)
        .type(ButtonType.Normal)
        .backgroundColor(this.selectedRole === 'USER' ? '#2B7FFF' : '#F0F2F5')
        .fontColor(this.selectedRole === 'USER' ? Color.White : '#333333')
        .borderRadius(6)
        .onClick(() => this.selectedRole = 'USER')
      Button('商家')
        .layoutWeight(1)
        .height(36)
        .fontSize(13)
        .type(ButtonType.Normal)
        .backgroundColor(this.selectedRole === 'SELLER' ? '#2B7FFF' : '#F0F2F5')
        .fontColor(this.selectedRole === 'SELLER' ? Color.White : '#333333')
        .borderRadius(6)
        .onClick(() => this.selectedRole = 'SELLER')
      Button('医生')
        .layoutWeight(1)
        .height(36)
        .fontSize(13)
        .type(ButtonType.Normal)
        .backgroundColor(this.selectedRole === 'PET_HOSPITAL' ? '#2B7FFF' : '#F0F2F5')
        .fontColor(this.selectedRole === 'PET_HOSPITAL' ? Color.White : '#333333')
        .borderRadius(6)
        .onClick(() => this.selectedRole = 'PET_HOSPITAL')
    }
    .width('100%')
  }
}
