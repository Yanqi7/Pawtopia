import { Api } from '../api/Api';
import { AppConfig } from '../app/AppConfig';
import { AppPrompt } from '../common/AppPrompt';
import { AppRouter } from '../common/AppRouter';
import { Theme } from '../common/Theme';
import { ErrorText, Field, PrimaryButton, SectionTitle } from '../components/Ui';
import { SessionStore } from '../store/SessionStore';

function roleLabel(role: string): string {
  return role === 'PET_SHOP' ? '宠物店' : role === 'PET_HOSPITAL' ? '宠物医院' : role === 'SELLER' ? '卖家' : role === 'ADMIN' ? '管理员' : '普通用户';
}

@Entry
@Component
struct ProfileSettings {
  @State private nickname: string = '';
  @State private phone: string = '';
  @State private baseUrl: string = AppConfig.DEFAULT_BASE_URL;
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private roleLabel: string = '';

  async aboutToAppear(): Promise<void> {
    const user = SessionStore.getUser();
    this.nickname = user?.nickname ?? '';
    this.phone = user?.phone ?? '';
    this.baseUrl = await SessionStore.getBaseUrl();
    this.roleLabel = roleLabel(user?.role ?? 'USER');
  }

  private async save(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      AppRouter.replace('pages/Login');
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      await SessionStore.setBaseUrl(this.baseUrl.trim() || AppConfig.DEFAULT_BASE_URL);
      const updated = await Api.updateUser(user.id, {
        nickname: this.nickname.trim() || undefined,
        phone: this.phone.trim() || undefined
      });
      await SessionStore.updateCurrentUser(updated);
      AppPrompt.toast('资料已保存');
      AppRouter.back();
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '保存失败';
    } finally {
      this.loading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Row() {
          Text('资料与服务设置')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Blank()
          Text('返回')
            .fontSize(14)
            .fontColor(Theme.primary)
            .onClick(() => AppRouter.back())
        }

        SectionTitle({ title: '账号资料' })
        Field({
          label: '角色',
          placeholder: '',
          value: this.roleLabel,
          onChange: () => {}
        })
        Field({
          label: '昵称',
          placeholder: '请输入昵称',
          value: this.nickname,
          onChange: (value: string) => this.nickname = value
        })
        Field({
          label: '手机号',
          placeholder: '请输入手机号',
          value: this.phone,
          onChange: (value: string) => this.phone = value,
          type: InputType.PhoneNumber
        })

        SectionTitle({ title: '服务连接' })
        Field({
          label: '后端地址',
          placeholder: AppConfig.DEFAULT_BASE_URL,
          value: this.baseUrl,
          onChange: (value: string) => this.baseUrl = value
        })

        ErrorText({ text: this.errorText })
        PrimaryButton({ text: this.loading ? '保存中…' : '保存设置', disabled: this.loading, action: () => this.save() })
      }
      .padding(16)
      .width('100%')
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }
}
