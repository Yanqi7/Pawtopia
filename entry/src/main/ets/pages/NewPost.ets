import { Api } from '../api/Api';
import { MediaAssets } from '../assets/MediaAssets';
import { ErrorText, PrimaryButton, SectionTitle } from '../components/Ui';
import { AppPrompt } from '../common/AppPrompt';
import { AppRouter } from '../common/AppRouter';
import { Theme } from '../common/Theme';
import { SessionStore } from '../store/SessionStore';

@Entry
@Component
struct NewPost {
  @State private title: string = '';
  @State private content: string = '';
  @State private coverKey: string = MediaAssets.postCoverKeys[0];
  @State private loading: boolean = false;
  @State private errorText: string = '';

  private async submit(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      AppRouter.replace('pages/Login');
      return;
    }
    if (!this.title.trim() || !this.content.trim()) {
      this.errorText = '请填写标题和正文';
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      await Api.createPost({
        title: this.title.trim(),
        content: this.content.trim(),
        userId: user.id,
        petId: undefined,
        imageUrls: this.coverKey
      });
      AppPrompt.toast('发布成功');
      AppRouter.back();
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '发布失败';
    } finally {
      this.loading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row({ space: 12 }) {
          Image($r('app.media.hero_back'))
            .width(24)
            .height(24)
            .onClick(() => AppRouter.back())
          Text('发布宠物动态')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.textPrimary)
          Blank()
          Image($r('app.media.hero_compose'))
            .width(26)
            .height(26)
        }
        .width('100%')

        Image(MediaAssets.postImage(this.coverKey, 0))
          .width('100%')
          .height(210)
          .borderRadius(26)
          .objectFit(ImageFit.Cover)

        Column({ space: 12 }) {
          SectionTitle({ title: '封面风格' })
          Row({ space: 10 }) {
            ForEach(MediaAssets.postCoverKeys, (cover: string) => {
              Image(MediaAssets.postImage(cover, 0))
                .width(74)
                .height(74)
                .borderRadius(18)
                .border({ width: this.coverKey === cover ? 3 : 1, color: this.coverKey === cover ? Theme.primary : Theme.border })
                .onClick(() => this.coverKey = cover)
            }, (cover: string) => cover)
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)

        Column({ space: 12 }) {
          SectionTitle({ title: '标题' })
          TextInput({ placeholder: '给你的动态起个吸引人的标题', text: this.title })
            .height(48)
            .backgroundColor('#F8FAFF')
            .border({ width: 1, color: Theme.border })
            .borderRadius(14)
            .padding({ left: 14, right: 14 })
            .onChange((value: string) => this.title = value)

          SectionTitle({ title: '正文' })
          TextArea({ placeholder: '写下今天和宠物相处的故事、经验或求助内容…', text: this.content })
            .height(220)
            .backgroundColor('#F8FAFF')
            .border({ width: 1, color: Theme.border })
            .borderRadius(18)
            .padding(14)
            .fontSize(14)
            .onChange((value: string) => this.content = value)

          if (this.errorText) {
            ErrorText({ text: this.errorText })
          }

          PrimaryButton({ text: this.loading ? '发布中…' : '发布动态', disabled: this.loading, action: () => this.submit() })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
      }
      .padding({ left: 16, right: 16, top: 18, bottom: 24 })
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.background)
  }
}
