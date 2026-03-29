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
                  .fill($r('sys.color.ohos_id_color_brand'))
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
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            TextInput({ placeholder: '请输入账号或手机号', text: this.username })
              .width('100%')
              .height(40)
              .padding({ left: 12, right: 12 })
              .borderRadius(8)
              .backgroundColor($r('sys.color.ohos_id_color_background'))
              .border({ width: 1, color: $r('sys.color.ohos_id_color_border') })
              .fontSize(14)
              .onChange((v: string) => this.username = v)
          }
          .width('100%')

          // Password input
          Column({ space: 6 }) {
            Text('密码')
              .fontSize(12)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            TextInput({ placeholder: '请输入密码', text: this.password })
              .width('100%')
              .height(40)
              .padding({ left: 12, right: 12 })
              .borderRadius(8)
              .backgroundColor($r('sys.color.ohos_id_color_background'))
              .border({ width: 1, color: $r('sys.color.ohos_id_color_border') })
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
              .backgroundColor($r('sys.color.ohos_id_color_brand'))
              .fontColor(Color.White)
              .borderRadius(6)
              .onClick(() => router.pushUrl({ url: 'pages/Register' }))

            Button('忘记密码?')
              .layoutWeight(1)
              .height(36)
              .fontSize(14)
              .type(ButtonType.Normal)
              .backgroundColor($r('sys.color.ohos_id_color_brand'))
              .fontColor(Color.White)
              .borderRadius(6)
          }

          // Identity selection
          Column({ space: 8 }) {
            Text('选择身份')
              .fontSize(12)
              .fontColor($r('sys.color.ohos_id_color_text_secondary'))
              .fontWeight(FontWeight.Medium)

            Row({ space: 12 }) {
              ForEach(['用户', '商家', '医生'], (label: string, index: number) => {
                const roles: UserRole[] = ['USER', 'SELLER', 'PET_HOSPITAL'];
                Button(label)
                  .layoutWeight(1)
                  .height(36)
                  .fontSize(13)
                  .type(ButtonType.Normal)
                  .backgroundColor(this.selectedRole === roles[index] ? $r('sys.color.ohos_id_color_brand') : $r('sys.color.ohos_id_color_button_normal'))
                  .fontColor(this.selectedRole === roles[index] ? Color.White : $r('sys.color.ohos_id_color_text_primary'))
                  .borderRadius(6)
                  .onClick(() => this.selectedRole = roles[index])
              })
            }
            .width('100%')
          }

          // Error message
          if (this.errorText) {
            Text(this.errorText)
              .fontSize(12)
              .fontColor($r('sys.color.ohos_id_color_text_warning'))
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
            .backgroundColor($r('sys.color.ohos_id_color_brand'))
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
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }
}
