import router from '@ohos.router';
import { Api } from '../api/Api';
import { Comment, Post } from '../model/Models';
import { SessionStore } from '../store/SessionStore';
import { PrimaryButton, ErrorText, SectionTitle } from '../components/Ui';

interface IdParams {
  id?: number;
}

@Entry
@Component
struct PostDetail {
  @State private postId: number = 0;
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private post: Post | undefined = undefined;
  @State private comments: Comment[] = [];
  @State private commentText: string = '';
  @State private submitting: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as IdParams;
    this.postId = Number(params?.id ?? 0);
    this.load();
  }

  private async load(): Promise<void> {
    if (!this.postId) {
      this.errorText = '无效帖子';
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      this.post = await Api.getPost(this.postId);
      const page = await Api.getComments(this.postId, 0, 50);
      this.comments = page.content;
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private async like(): Promise<void> {
    if (!this.postId) {
      return;
    }
    try {
      const updated = await Api.likePost(this.postId);
      if (this.post) {
        const cur = this.post;
        const next: Post = {
          id: cur.id,
          title: cur.title,
          content: cur.content,
          userId: cur.userId,
          petId: cur.petId,
          imageUrls: cur.imageUrls,
          viewCount: cur.viewCount,
          likeCount: updated.likeCount,
          commentCount: cur.commentCount,
          createdAt: cur.createdAt,
          updatedAt: cur.updatedAt
        };
        this.post = next;
      }
    } catch (e) {
      this.errorText = (e as Error).message || '点赞失败';
    }
  }

  private async submitComment(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      router.replaceUrl({ url: 'pages/Login' });
      return;
    }
    const userId = user.id;
    if (!this.commentText.trim()) {
      return;
    }
    this.submitting = true;
    try {
      await Api.createComment({
        postId: this.postId,
        userId: userId,
        parentId: undefined,
        content: this.commentText.trim()
      });
      this.commentText = '';
      await this.load();
    } catch (e) {
      this.errorText = (e as Error).message || '评论失败';
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Row() {
          Text('帖子详情').fontSize(18).fontWeight(FontWeight.Bold)
          Blank()
          Text('返回').fontSize(14).fontColor('#2B7FFF').onClick(() => router.back())
        }

        if (this.errorText) {
          ErrorText({ text: this.errorText })
        }

        if (this.post) {
          Column({ space: 8 }) {
            Text(this.post!.title).fontSize(18).fontWeight(FontWeight.Bold)
            Text(this.post!.content).fontSize(14).fontColor('#333')
            Row({ space: 10 }) {
              Button('点赞')
                .height(32)
                .borderRadius(16)
                .backgroundColor('#2B7FFF')
                .fontColor(Color.White)
                .onClick(() => this.like())
              Text(`👍 ${this.post!.likeCount ?? 0}`).fontSize(12).fontColor('#666')
              Text(`💬 ${this.post!.commentCount ?? 0}`).fontSize(12).fontColor('#666')
              Text(`👁 ${this.post!.viewCount ?? 0}`).fontSize(12).fontColor('#666')
            }
          }
          .padding(12)
          .backgroundColor('#F6F7F9')
          .borderRadius(12)
        } else if (this.loading) {
          Text('加载中…').fontSize(13).fontColor('#666')
        }

        SectionTitle({ title: `评论（${this.comments.length}）` })
        Column({ space: 6 }) {
          TextArea({ placeholder: '写下你的看法…', text: this.commentText })
            .height(96)
            .backgroundColor('#F6F7F9')
            .borderRadius(10)
            .padding(12)
            .onChange((v: string) => this.commentText = v)
          PrimaryButton({ text: this.submitting ? '提交中…' : '发表评论', disabled: this.submitting, action: () => this.submitComment() })
        }

        ForEach(this.comments, (c: Comment) => {
          Column({ space: 6 }) {
            Text(c.content).fontSize(14).fontColor('#333')
            Text(`点赞 ${c.likeCount ?? 0}`).fontSize(12).fontColor('#999')
          }
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .border({ width: 1, color: '#EEE' })
        }, (c: Comment) => String(c.id))
      }
      .padding(16)
      .width('100%')
    }
    .height('100%')
    .width('100%')
  }
}
