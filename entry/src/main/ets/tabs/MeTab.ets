import router from '@ohos.router';
import { SessionStore } from '../store/SessionStore';
import { Api } from '../api/Api';
import { User } from '../model/Models';
import { PrimaryButton, Field, ErrorText, SectionTitle, OfflineBanner } from '../components/Ui';
import { AppStatus } from '../app/AppStatus';

function roleLabel(role: string): string {
  switch (role) {
    case 'PET_SHOP':
      return '宠物店';
    case 'PET_HOSPITAL':
      return '宠物医院';
    case 'SELLER':
      return '卖家';
    case 'ADMIN':
      return '管理员';
    default:
      return '普通用户';
  }
}

@Component
export struct MeTab {
  @State private user?: User = SessionStore.getUser();
  @State private nickname: string = this.user?.nickname ?? '';
  @State private phone: string = this.user?.phone ?? '';
  @State private loading: boolean = false;
  @State private errorText: string = '';

  aboutToAppear(): void {
    this.user = SessionStore.getUser();
    this.nickname = this.user?.nickname ?? '';
    this.phone = this.user?.phone ?? '';
  }

  private async save(): Promise<void> {
    const u = SessionStore.getUser();
    if (!u || !u.id) {
      return;
    }
    const userId = u.id;
    this.loading = true;
    this.errorText = '';
    try {
      const updated = await Api.updateUser(userId, { nickname: this.nickname.trim(), phone: this.phone.trim() });
      await SessionStore.login(updated, SessionStore.getRole());
      this.user = updated;
    } catch (e) {
      this.errorText = (e as Error).message || '保存失败';
    } finally {
      this.loading = false;
    }
  }

  private async logout(): Promise<void> {
    await SessionStore.logout();
    router.replaceUrl({ url: 'pages/Login' });
  }

  build() {
    Column() {
      Row() {
        Column({ space: 2 }) {
          Text('我的')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Text(SessionStore.isLoggedIn() ? `已登录：${SessionStore.getUser()!.username}` : '未登录')
            .fontSize(11)
            .fontColor('#888')
        }
        Blank()
        Button('领养申请')
          .height(32)
          .borderRadius(16)
          .backgroundColor('#F0F2F5')
          .onClick(() => router.pushUrl({ url: 'pages/MyAdoptions' }))
        Button('订单')
          .height(32)
          .borderRadius(16)
          .backgroundColor('#F0F2F5')
          .onClick(() => router.pushUrl({ url: 'pages/Orders' }))
      }
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      Scroll() {
        Column({ space: 14 }) {
          if (!AppStatus.isBackendOnline()) {
            OfflineBanner({ action: () => router.pushUrl({ url: 'pages/Login' }) })
          }

          SectionTitle({ title: '账号信息' })
          if (this.user) {
            Text(`用户名：${this.user!.username}`).fontSize(13).fontColor('#666')
          } else {
            Text('未登录').fontSize(13).fontColor('#666')
          }
          Text(`身份：${roleLabel(SessionStore.getRole())}`).fontSize(13).fontColor('#666')

          if (!this.user) {
            PrimaryButton({ text: '去登录/设置服务器', disabled: false, action: () => router.pushUrl({ url: 'pages/Login' }) })
          } else {
            SectionTitle({ title: '资料' })
            Field({
              label: '昵称',
              placeholder: '你的昵称',
              value: this.nickname,
              onChange: (v: string) => this.nickname = v
            })
            Field({
              label: '手机号',
              placeholder: '可选',
              value: this.phone,
              onChange: (v: string) => this.phone = v
            })
            ErrorText({ text: this.errorText })
            PrimaryButton({ text: this.loading ? '保存中…' : '保存资料', disabled: this.loading, action: () => this.save() })

            SectionTitle({ title: '退出' })
            PrimaryButton({ text: '退出登录', disabled: false, action: () => this.logout() })
          }
        }
        .padding({ left: 16, right: 16, bottom: 24 })
        .width('100%');
      }
      .height('100%');
    }
    .height('100%')
    .width('100%')
  }
}
