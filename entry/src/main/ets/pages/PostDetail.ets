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
    Column() {
      // 顶部导航
      Row({ space: 12 }) {
        Image($r('app.media.more'))
          .width(24)
          .height(24)
          .fillColor('#2B7FFF')
          .onClick(() => router.back())
        Blank()
        Text('帖子详情')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Blank()
        Image($r('app.media.more'))
          .width(24)
          .height(24)
          .fillColor('#999')
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .width('100%')
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: '#F0F0F0' })

      Scroll() {
        Column({ space: 16 }) {
          if (this.errorText) {
            Text(this.errorText)
              .fontSize(13)
              .fontColor(Color.Red)
              .padding(16)
          }

          if (this.post) {
            // 帖子头部信息
            Column({ space: 12 }) {
              // 用户信息
              Row({ space: 12 }) {
                Image($r('app.media.people'))
                  .width(40)
                  .height(40)
                  .borderRadius(20)

                Column({ space: 4 }) {
                  Text('发布者')
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                  Text('3小时前')
                    .fontSize(12)
                    .fontColor('#999')
                }
                .layoutWeight(1)

                Text('…')
                  .fontSize(16)
                  .fontColor('#999')
              }
              .width('100%')

              // 帖子标题
              Text(this.post!.title)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .width('100%')

              // 帖子内容
              Text(this.post!.content)
                .fontSize(14)
                .fontColor('#333')
                .width('100%')
                .lineHeight(1.6)

              // 帖子图片（如有）
              if (this.post!.imageUrls) {
                Image($r('app.media.dog'))
                  .width('100%')
                  .height(200)
                  .borderRadius(8)
                  .objectFit(ImageFit.Cover)
              }

              // 互动数据
              Row({ space: 20 }) {
                Column({ space: 4 }) {
                  Text(`${this.post!.likeCount ?? 0}`)
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                  Text('赞')
                    .fontSize(12)
                    .fontColor('#999')
                }
                .alignItems(HorizontalAlign.Center)

                Column({ space: 4 }) {
                  Text(`${this.post!.commentCount ?? 0}`)
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                  Text('评论')
                    .fontSize(12)
                    .fontColor('#999')
                }
                .alignItems(HorizontalAlign.Center)

                Column({ space: 4 }) {
                  Text(`${this.post!.viewCount ?? 0}`)
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                  Text('浏览')
                    .fontSize(12)
                    .fontColor('#999')
                }
                .alignItems(HorizontalAlign.Center)

                Blank()

                Button('👍 点赞')
                  .height(36)
                  .fontSize(12)
                  .backgroundColor('#FFE8E8')
                  .fontColor('#FF6B6B')
                  .borderRadius(18)
                  .onClick(() => this.like())
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .backgroundColor('#F9F9F9')
              .borderRadius(8)
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
          } else if (this.loading) {
            Text('加载中…')
              .fontSize(14)
              .fontColor('#999')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(40)
          }

          // 评论区域
          Column({ space: 12 }) {
            Text(`评论（${this.comments.length}）`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)

            // 评论输入框
            Column({ space: 8 }) {
              TextArea({ placeholder: '发表你的看法…', text: this.commentText })
                .height(80)
                .backgroundColor('#F9F9F9')
                .border({ width: 1, color: '#E8E8E8' })
                .borderRadius(8)
                .padding(12)
                .onChange((v: string) => this.commentText = v)

              Button(this.submitting ? '发表中…' : '发表评论')
                .width('100%')
                .height(40)
                .backgroundColor('#2B7FFF')
                .fontColor(Color.White)
                .borderRadius(8)
                .enabled(!this.submitting)
                .onClick(() => this.submitComment())
            }
            .padding(12)
            .backgroundColor(Color.White)
            .borderRadius(12)

            // 评论列表
            ForEach(this.comments, (c: Comment) => {
              Column({ space: 8 }) {
                Row({ space: 8 }) {
                  Image($r('app.media.people'))
                    .width(32)
                    .height(32)
                    .borderRadius(16)

                  Column({ space: 4 }) {
                    Text('评论者')
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                    Text('1小时前')
                      .fontSize(10)
                      .fontColor('#999')
                  }
                  .layoutWeight(1)

                  Text('赞 ' + (c.likeCount ?? 0))
                    .fontSize(11)
                    .fontColor('#2B7FFF')
                }
                .width('100%')

                Text(c.content)
                  .fontSize(13)
                  .fontColor('#333')
                  .width('100%')
                  .lineHeight(1.5)
              }
              .padding(12)
              .backgroundColor(Color.White)
              .borderRadius(8)
              .width('100%')
            }, (c: Comment) => String(c.id))
          }
          .padding(16)
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F5F5F5')
  }
}
