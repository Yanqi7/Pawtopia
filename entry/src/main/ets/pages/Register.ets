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
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          Blank().height(20)

          // Title
          Column({ space: 4 }) {
            Text('注册账户')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            Text('选择你的身份，进入不同的功能视图')
              .fontSize(12)
              .fontColor('#666666')
          }
          .width('100%')

          // Username
          Column({ space: 6 }) {
            Text('用户名')
              .fontSize(12)
              .fontColor('#666666')
            TextInput({ placeholder: '唯一用户名', text: this.username })
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

          // Password
          Column({ space: 6 }) {
            Text('密码')
              .fontSize(12)
              .fontColor('#666666')
            TextInput({ placeholder: '至少6位', text: this.password })
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

          // Email
          Column({ space: 6 }) {
            Text('邮箱')
              .fontSize(12)
              .fontColor('#666666')
            TextInput({ placeholder: '用于找回密码', text: this.email })
              .width('100%')
              .height(40)
              .padding({ left: 12, right: 12 })
              .borderRadius(8)
              .backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#E8E8E8' })
              .fontSize(14)
              .onChange((v: string) => this.email = v)
          }
          .width('100%')

          // Nickname
          Column({ space: 6 }) {
            Text('昵称（可选）')
              .fontSize(12)
              .fontColor('#666666')
            TextInput({ placeholder: '你的昵称', text: this.nickname })
              .width('100%')
              .height(40)
              .padding({ left: 12, right: 12 })
              .borderRadius(8)
              .backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#E8E8E8' })
              .fontSize(14)
              .onChange((v: string) => this.nickname = v)
          }
          .width('100%')

          // Role selection
          Column({ space: 8 }) {
            Text('选择身份')
              .fontSize(12)
              .fontColor('#666666')
              .fontWeight(FontWeight.Medium)
            this.RoleSelectionRow()
          }

          // Error
          if (this.errorText) {
            Text(this.errorText)
              .fontSize(12)
              .fontColor('#ff4d4f')
              .width('100%')
              .textAlign(TextAlign.Center)
          }

          // Register button
          Button(this.loading ? '注册中…' : '完成注册')
            .width('100%')
            .height(44)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .type(ButtonType.Capsule)
            .backgroundColor('#2B7FFF')
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
