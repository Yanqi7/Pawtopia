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
  @State private passwordVisible: boolean = false;
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
    Stack() {
      // 渐变背景
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [['#E8EEF2', 0.0], ['#F0E8FF', 0.5], ['#F0FFF8', 1.0]]
        })

      // 装饰元素：爪子印和骨头
      Stack() {
        // 左上爪子
        Image($r('app.media.paw'))
          .width(80)
          .height(80)
          .opacity(0.15)
          .position({ left: -20, top: -20 })

        // 右上骨头
        Image($r('app.media.paw_1'))
          .width(60)
          .height(60)
          .opacity(0.12)
          .position({ right: -10, top: 20 })

        // 左下骨头
        Image($r('app.media.paw_1'))
          .width(70)
          .height(70)
          .opacity(0.12)
          .position({ left: 0, bottom: 150 })

        // 右下爪子
        Image($r('app.media.paw'))
          .width(85)
          .height(85)
          .opacity(0.1)
          .position({ right: -30, bottom: -30 })
      }
      .width('100%')
      .height('100%')

      // 主内容
      Scroll() {
        Column({ space: 20 }) {
          Blank().height(30)

          // APP标题和狗狗头像
          Row() {
            Blank()
            Column({ space: 4 }) {
              Text('APP')
                .fontSize(36)
                .fontWeight(FontWeight.Bold)
                .fontColor('#6B8EFF')
              Stack() {
                Circle()
                  .width(70)
                  .height(70)
                  .fill('#B3D9FF')
                Image($r('app.media.dog'))
                  .width(65)
                  .height(65)
                  .borderRadius(32)
                  .objectFit(ImageFit.Cover)
              }
            }
            .alignItems(HorizontalAlign.Center)
            Blank()
          }
          .width('100%')

          // 账号输入框
          Row({ space: 12 }) {
            Image($r('app.media.ic_people'))
              .width(20)
              .height(20)
              .fillColor('#999')
            Column() {
              TextInput({ placeholder: '请输入账号/手机号', text: this.username })
                .width('100%')
                .height(44)
                .backgroundColor('transparent')
                .fontSize(14)
                .onChange((v: string) => this.username = v)
            }
            .layoutWeight(1)
            .height(44)
            .justifyContent(FlexAlign.Center)

            Divider()
              .vertical(true)
              .strokeWidth(1)
              .color('#DDD')
              .height(20)

            if (this.username) {
              Text('清除')
                .fontSize(12)
                .fontColor('#2B7FFF')
                .onClick(() => this.username = '')
                .padding({ right: 4 })
            }
          }
          .padding({ left: 16, right: 12 })
          .height(44)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#E0E0E0' })
          .borderRadius(22)

          // 密码输入框
          Row({ space: 12 }) {
            Image($r('app.media.lock'))
              .width(20)
              .height(20)
              .fillColor('#999')
            Column() {
              TextInput({ placeholder: '请输入密码', text: this.password })
                .width('100%')
                .height(44)
                .backgroundColor('transparent')
                .fontSize(14)
                .type(this.passwordVisible ? InputType.Normal : InputType.Password)
                .onChange((v: string) => this.password = v)
            }
            .layoutWeight(1)
            .height(44)
            .justifyContent(FlexAlign.Center)

            Divider()
              .vertical(true)
              .strokeWidth(1)
              .color('#DDD')
              .height(20)

            Text(this.passwordVisible ? '隐藏' : '显示')
              .fontSize(12)
              .fontColor('#2B7FFF')
              .onClick(() => this.passwordVisible = !this.passwordVisible)
              .padding({ right: 4 })
          }
          .padding({ left: 16, right: 12 })
          .height(44)
          .backgroundColor('#FFFFFF')
          .border({ width: 1, color: '#E0E0E0' })
          .borderRadius(22)

          // 注册和忘记密码按钮
          Row({ space: 12 }) {
            Button('注册')
              .layoutWeight(1)
              .height(40)
              .fontSize(14)
              .fontColor(Color.White)
              .backgroundColor('#2B7FFF')
              .borderRadius(20)
              .onClick(() => router.pushUrl({ url: 'pages/Register' }))

            Button('忘记密码?')
              .layoutWeight(1)
              .height(40)
              .fontSize(14)
              .fontColor(Color.White)
              .backgroundColor('#2B7FFF')
              .borderRadius(20)
          }

          // 身份选择
          Column({ space: 10 }) {
            Text('身份选择')
              .fontSize(14)
              .fontColor('#333')
              .fontWeight(FontWeight.Medium)

            Row({ space: 12 }) {
              Button('用户')
                .layoutWeight(1)
                .height(36)
                .fontSize(13)
                .backgroundColor(this.selectedRole === 'USER' ? '#FFFFFF' : '#FFFFFF')
                .fontColor(this.selectedRole === 'USER' ? '#FF9D4E' : '#666')
                .border({ width: 1, color: this.selectedRole === 'USER' ? '#FF9D4E' : '#DDD' })
                .borderRadius(18)
                .onClick(() => this.selectedRole = 'USER')

              Button('商家')
                .layoutWeight(1)
                .height(36)
                .fontSize(13)
                .backgroundColor(this.selectedRole === 'SELLER' ? '#FFB88C' : '#FFFFFF')
                .fontColor(this.selectedRole === 'SELLER' ? Color.White : '#666')
                .border({ width: 1, color: this.selectedRole === 'SELLER' ? '#FF9D4E' : '#DDD' })
                .borderRadius(18)
                .onClick(() => this.selectedRole = 'SELLER')

              Button('医生')
                .layoutWeight(1)
                .height(36)
                .fontSize(13)
                .backgroundColor(this.selectedRole === 'PET_HOSPITAL' ? '#FFFFFF' : '#FFFFFF')
                .fontColor(this.selectedRole === 'PET_HOSPITAL' ? '#FF9D4E' : '#666')
                .border({ width: 1, color: this.selectedRole === 'PET_HOSPITAL' ? '#FF9D4E' : '#DDD' })
                .borderRadius(18)
                .onClick(() => this.selectedRole = 'PET_HOSPITAL')
            }
            .width('100%')
          }

          // 错误信息
          if (this.errorText) {
            Text(this.errorText)
              .fontSize(12)
              .fontColor(Color.Red)
              .width('100%')
              .textAlign(TextAlign.Center)
          }

          // 登录按钮
          Stack() {
            Button()
              .width('100%')
              .height(50)
              .borderRadius(25)
              .linearGradient({
                angle: 90,
                colors: [['#FF9D4E', 0.0], ['#FFB347', 1.0]]
              })
              .enabled(!this.loading)
              .onClick(() => this.doLogin())

            Row() {
              Blank()
              Text(this.loading ? '登录中…' : '登 录')
                .fontSize(16)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
              Blank()
              if (this.loading) {
                Image($r('app.media.more'))
                  .width(20)
                  .height(20)
                  .fillColor(Color.White)
                  .animation({
                    duration: 1000,
                    curve: Curve.Linear,
                    playMode: PlayMode.Normal
                  })
              }
            }
            .width('100%')
            .height(50)
            .padding({ right: 20 })
          }

          Blank()
        }
        .padding({ left: 20, right: 20 })
        .width('100%')
      }
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
