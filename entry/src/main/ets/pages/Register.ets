import router from '@ohos.router';
import { Api } from '../api/Api';
import { UserRole } from '../model/Models';

@Entry
@Component
struct Register {
  @State private username: string = '';
  @State private password: string = '';
  @State private email: string = '';
  @State private nickname: string = '';
  @State private selectedRole: UserRole = 'USER';
  @State private loading: boolean = false;
  @State private errorText: string = '';

  private async doRegister(): Promise<void> {
    if (!this.username || !this.password || !this.email) {
      this.errorText = '请填写用户名、密码、邮箱';
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      await Api.register(
        this.username.trim(),
        this.password,
        this.email.trim(),
        this.nickname.trim(),
        this.selectedRole
      );
      router.replaceUrl({ url: 'pages/MainTabs' });
    } catch (e) {
      this.errorText = (e as Error).message || '注册失败';
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
        Column({ space: 16 }) {
          Blank().height(20)

          // Title
          Column({ space: 4 }) {
            Text('注  册').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#333')
            Text('选择你的身份，进入不同的功能视图').fontSize(12).fontColor('#666')
          }.width('100%')

          // Username
          Column({ space: 2 }) {
            Text('用户名').fontSize(13).fontColor('#666')
            Row({ space: 8 }) {
              Image($r('app.media.ic_people')).width(20).height(20)
              TextInput({ placeholder: '唯一用户名', text: this.username })
                .layoutWeight(1)
                .onChange((v: string) => this.username = v)
            }
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .borderRadius(8)
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#E0E0E0' })
          }.width('100%')

          // Password
          Column({ space: 2 }) {
            Text('密码').fontSize(13).fontColor('#666')
            Row({ space: 8 }) {
              Image($r('app.media.lock')).width(20).height(20)
              TextInput({ placeholder: '至少4位', text: this.password, type: InputType.Password })
                .layoutWeight(1)
                .onChange((v: string) => this.password = v)
            }
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .borderRadius(8)
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#E0E0E0' })
          }.width('100%')

          // Email
          Column({ space: 2 }) {
            Text('邮箱').fontSize(13).fontColor('#666')
            TextInput({ placeholder: '用于找回密码', text: this.email })
              .width('100%')
              .height(40)
              .padding({ left: 12, right: 12 })
              .borderRadius(8)
              .backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#E0E0E0' })
              .onChange((v: string) => this.email = v)
          }.width('100%')

          // Nickname
          Column({ space: 2 }) {
            Text('昵称').fontSize(13).fontColor('#666')
            TextInput({ placeholder: '可选', text: this.nickname })
              .width('100%')
              .height(40)
              .padding({ left: 12, right: 12 })
              .borderRadius(8)
              .backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#E0E0E0' })
              .onChange((v: string) => this.nickname = v)
          }.width('100%')

          // Role selection
          Column({ space: 2 }) {
            Text('身份选择').fontSize(13).fontColor('#666')
            Row({ space: 10 }) {
              this.RoleButton('用户', 'USER')
              this.RoleButton('商家', 'SELLER')
              this.RoleButton('医生', 'PET_HOSPITAL')
            }.width('100%')
          }

          // Error
          if (this.errorText) {
            Text(this.errorText).fontSize(12).fontColor(Color.Red).width('100%').textAlign(TextAlign.Center)
          }

          // Register button
          Button(this.loading ? '提交中…' : '提 交 注 册')
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
            .onClick(() => this.doRegister())

          // Back to login
          Text('返回登录')
            .fontSize(13)
            .fontColor('#2B7FFF')
            .onClick(() => router.back())

          Blank()
        }
        .padding({ left: 20, right: 20, bottom: 30 })
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
