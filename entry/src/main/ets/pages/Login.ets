import router from '@ohos.router';
import { Api } from '../api/Api';
import promptAction from '@ohos.promptAction';
import { PrimaryButton, Field, ErrorText, SectionTitle, OptionGroup } from '../components/Ui';
import { AppConfig } from '../app/AppConfig';
import { PreferencesStore } from '../store/PreferencesStore';
import { SessionStore } from '../store/SessionStore';
import { UserRole } from '../model/Models';

const ROLE_LABELS: string[] = ['普通用户', '宠物店', '宠物医院', '卖家', '管理员'];
const ROLE_VALUES: UserRole[] = ['USER', 'PET_SHOP', 'PET_HOSPITAL', 'SELLER', 'ADMIN'];

function roleLabelFromValue(value: string): string {
  const idx = ROLE_VALUES.findIndex((v: UserRole) => v === (value as UserRole));
  return idx >= 0 ? ROLE_LABELS[idx] : ROLE_LABELS[0];
}

@Entry
@Component
struct Login {
  @State private username: string = '';
  @State private password: string = '';
  @State private baseUrl: string = AppConfig.DEFAULT_BASE_URL;
  @State private savingBaseUrl: boolean = false;
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private roleLabel: string = roleLabelFromValue('USER');

  aboutToAppear(): void {
    const context = getContext(this);
    PreferencesStore.init(context).then(async () => {
      this.baseUrl = await PreferencesStore.getString(AppConfig.PREF_KEY_BASE_URL, AppConfig.DEFAULT_BASE_URL);
      this.roleLabel = roleLabelFromValue(SessionStore.getRole());
    });
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

  private async saveBaseUrl(): Promise<void> {
    if (!this.baseUrl) {
      return;
    }
    this.savingBaseUrl = true;
    try {
      await SessionStore.setBaseUrl(this.baseUrl.trim());
    } finally {
      this.savingBaseUrl = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('城宠部落 Pawtopia').fontSize(22).fontWeight(FontWeight.Bold)
        Text('登录后进入：社区 / 领养 / 医疗 / 商城').fontSize(13).fontColor('#666')

        SectionTitle({ title: '账号' })
        Field({
          label: '用户名',
          placeholder: '例如：user1',
          value: this.username,
          onChange: (v: string) => this.username = v
        })
        Field({
          label: '密码',
          placeholder: '请输入密码',
          value: this.password,
          onChange: (v: string) => this.password = v,
          type: InputType.Password
        })
        OptionGroup({
          label: '身份（登录自动识别）',
          options: ROLE_LABELS,
          selected: this.roleLabel,
          onSelect: () => {
            this.roleLabel = roleLabelFromValue(SessionStore.getRole());
            promptAction.showToast({ message: '登录无需选择身份，系统会自动识别' });
          }
        })
        ErrorText({ text: this.errorText })
        PrimaryButton({ text: this.loading ? '登录中…' : '登录', disabled: this.loading, action: () => this.doLogin() })
        PrimaryButton({
          text: '一键登录管理员（user1）',
          disabled: this.loading,
          action: () => {
            this.username = 'user1';
            this.password = 'user1';
            this.doLogin();
          }
        })

        Row() {
          Text('没有账号？')
            .fontSize(13)
            .fontColor('#666')
          Text('去注册')
            .fontSize(13)
            .fontColor('#2B7FFF')
            .margin({ left: 6 })
            .onClick(() => router.pushUrl({ url: 'pages/Register' }))
        }.margin({ top: 4 })

        SectionTitle({ title: '服务器' })
        Field({
          label: '后端地址',
          placeholder: AppConfig.DEFAULT_BASE_URL,
          value: this.baseUrl,
          onChange: (v: string) => this.baseUrl = v
        })
        PrimaryButton({ text: this.savingBaseUrl ? '保存中…' : '保存地址', disabled: this.savingBaseUrl, action: () => this.saveBaseUrl() })
        Text('提示：模拟器通常用 10.0.2.2，真机请填局域网 IP。')
          .fontSize(12)
          .fontColor('#888')
          .margin({ top: 4 })
      }
      .padding(20)
      .width('100%')
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
