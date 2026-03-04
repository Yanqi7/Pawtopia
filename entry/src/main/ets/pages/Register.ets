import router from '@ohos.router';
import { Api } from '../api/Api';
import { PrimaryButton, Field, ErrorText, SectionTitle, OptionGroup } from '../components/Ui';
import { UserRole } from '../model/Models';

const ROLE_LABELS: string[] = ['普通用户', '宠物店', '宠物医院', '卖家'];
const ROLE_VALUES: UserRole[] = ['USER', 'PET_SHOP', 'PET_HOSPITAL', 'SELLER'];

function roleValueFromLabel(label: string): UserRole {
  const idx = ROLE_LABELS.findIndex((v: string) => v === label);
  return idx >= 0 ? ROLE_VALUES[idx] : 'USER';
}

@Entry
@Component
struct Register {
  @State private username: string = '';
  @State private password: string = '';
  @State private email: string = '';
  @State private nickname: string = '';
  @State private role: UserRole = 'USER';
  @State private roleLabel: string = ROLE_LABELS[0];
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
        this.role
      );
      router.replaceUrl({ url: 'pages/MainTabs' });
    } catch (e) {
      this.errorText = (e as Error).message || '注册失败';
    } finally {
      this.loading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Text('注册').fontSize(22).fontWeight(FontWeight.Bold)
        Text('选择你的身份，进入不同的功能视图').fontSize(13).fontColor('#666')

        SectionTitle({ title: '信息' })
        Field({
          label: '用户名',
          placeholder: '唯一用户名',
          value: this.username,
          onChange: (v: string) => this.username = v
        })
        Field({
          label: '密码',
          placeholder: '至少 4 位',
          value: this.password,
          onChange: (v: string) => this.password = v,
          type: InputType.Password
        })
        Field({
          label: '邮箱',
          placeholder: '用于找回密码',
          value: this.email,
          onChange: (v: string) => this.email = v
        })
        Field({
          label: '昵称',
          placeholder: '可选',
          value: this.nickname,
          onChange: (v: string) => this.nickname = v
        })

        SectionTitle({ title: '身份' })
        OptionGroup({
          label: '选择身份',
          options: ROLE_LABELS,
          selected: this.roleLabel,
          onSelect: (v: string) => {
            this.roleLabel = v;
            this.role = roleValueFromLabel(v);
          }
        })

        ErrorText({ text: this.errorText })
        PrimaryButton({ text: this.loading ? '提交中…' : '提交注册', disabled: this.loading, action: () => this.doRegister() })

        Text('返回登录')
          .fontSize(13)
          .fontColor('#2B7FFF')
          .margin({ top: 8 })
          .onClick(() => router.back())
      }
      .padding(20)
      .width('100%')
    }
    .height('100%')
    .width('100%')
  }
}
