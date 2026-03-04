import router from '@ohos.router';
import { Api } from '../api/Api';
import { PrimaryButton, Field, ErrorText, SectionTitle } from '../components/Ui';
import { SessionStore } from '../store/SessionStore';

@Entry
@Component
struct NewPost {
  @State private title: string = '';
  @State private content: string = '';
  @State private loading: boolean = false;
  @State private errorText: string = '';

  private async submit(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      router.replaceUrl({ url: 'pages/Login' });
      return;
    }
    const userId = user.id;
    if (!this.title.trim() || !this.content.trim()) {
      this.errorText = '请填写标题与内容';
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      await Api.createPost({
        title: this.title.trim(),
        content: this.content.trim(),
        userId: userId,
        petId: undefined,
        imageUrls: ''
      });
      router.back();
    } catch (e) {
      this.errorText = (e as Error).message || '发布失败';
    } finally {
      this.loading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Row() {
          Text('发布帖子').fontSize(18).fontWeight(FontWeight.Bold)
          Blank()
          Text('返回').fontSize(14).fontColor('#2B7FFF').onClick(() => router.back())
        }
        SectionTitle({ title: '内容' })
        Field({
          label: '标题',
          placeholder: '一句话说明你想分享什么',
          value: this.title,
          onChange: (v: string) => this.title = v
        })
        Column({ space: 6 }) {
          Text('正文').fontSize(13).fontColor('#444')
          TextArea({ placeholder: '写点什么吧…', text: this.content })
            .height(200)
            .backgroundColor('#F6F7F9')
            .borderRadius(10)
            .padding(12)
            .onChange((v: string) => this.content = v)
        }.width('100%')
        ErrorText({ text: this.errorText })
        PrimaryButton({ text: this.loading ? '发布中…' : '发布', disabled: this.loading, action: () => this.submit() })
      }
      .padding(16)
      .width('100%')
    }
    .height('100%')
    .width('100%')
  }
}
