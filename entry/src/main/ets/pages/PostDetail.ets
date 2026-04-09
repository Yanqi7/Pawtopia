import { Api } from '../api/Api';
import { MediaAssets } from '../assets/MediaAssets';
import { EmptyState, ErrorText } from '../components/Ui';
import { AppRouter } from '../common/AppRouter';
import { postAuthorLabel, relativeTime } from '../common/Formatters';
import { Theme } from '../common/Theme';
import { Comment, Post } from '../model/Models';
import { SessionStore } from '../store/SessionStore';

interface IdParams {
  id?: number;
}

interface CommentThread {
  comment: Comment;
  replies: Comment[];
}

@Entry
@Component
struct PostDetail {
  @State private postId: number = 0;
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private post?: Post = undefined;
  @State private threads: CommentThread[] = [];
  @State private commentText: string = '';
  @State private submitting: boolean = false;
  @State private replyTo?: Comment = undefined;

  aboutToAppear(): void {
    const params = AppRouter.params<IdParams>();
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
      const comments = await Api.getTopLevelComments(this.postId);
      const replies = await Promise.all(comments.map((comment: Comment) => comment.id ? Api.getRepliesByParent(comment.id).catch(() => []) : Promise.resolve([])));
      this.threads = comments.map((comment: Comment, index: number) => {
        const thread: CommentThread = {
          comment: comment,
          replies: replies[index]
        };
        return thread;
      });
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private async like(): Promise<void> {
    if (!this.postId || !this.post) {
      return;
    }
    try {
      const updated = await Api.likePost(this.postId);
      const current = this.post;
      this.post = {
        id: current.id,
        title: current.title,
        content: current.content,
        userId: current.userId,
        petId: current.petId,
        imageUrls: current.imageUrls,
        viewCount: current.viewCount,
        likeCount: updated.likeCount ?? current.likeCount,
        commentCount: current.commentCount,
        createdAt: current.createdAt,
        updatedAt: current.updatedAt
      };
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '点赞失败';
    }
  }

  private startReply(comment: Comment): void {
    this.replyTo = comment;
    this.commentText = `@${postAuthorLabel(comment.userId)} `;
  }

  private cancelReply(): void {
    this.replyTo = undefined;
    this.commentText = '';
  }

  private async submitComment(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      AppRouter.replace('pages/Login');
      return;
    }
    if (!this.commentText.trim()) {
      return;
    }
    this.submitting = true;
    try {
      await Api.createComment({
        postId: this.postId,
        userId: user.id,
        parentId: this.replyTo?.id,
        content: this.commentText.trim()
      });
      this.commentText = '';
      this.replyTo = undefined;
      await this.load();
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '评论失败';
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Image($r('app.media.hero_back'))
          .width(24)
          .height(24)
          .onClick(() => AppRouter.back())
        Text('帖子详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.textPrimary)
        Blank()
        Image($r('app.media.hero_bell'))
          .width(24)
          .height(24)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 12 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column({ space: 16 }) {
          if (this.errorText) {
            ErrorText({ text: this.errorText })
          }

          if (this.loading && !this.post) {
            Column({ space: 10 }) {
              LoadingProgress()
                .width(24)
                .height(24)
                .color(Theme.primary)
              Text('正在加载帖子内容…')
                .fontSize(13)
                .fontColor(Theme.textSecondary)
            }
            .width('100%')
            .padding(24)
            .alignItems(HorizontalAlign.Center)
          }

          if (this.post) {
            Column({ space: 14 }) {
              Image(MediaAssets.postImage(this.post!.imageUrls, this.post!.id ?? 0))
                .width('100%')
                .height(240)
                .borderRadius(26)
                .objectFit(ImageFit.Cover)

              Row({ space: 12 }) {
                Image(MediaAssets.avatar())
                  .width(44)
                  .height(44)
                  .borderRadius(22)
                Column({ space: 4 }) {
                  Text(postAuthorLabel(this.post!.userId))
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Theme.textPrimary)
                  Text(relativeTime(this.post!.createdAt))
                    .fontSize(12)
                    .fontColor(Theme.textMuted)
                }
                .layoutWeight(1)
                Text(`#${this.post!.id ?? '-'}`)
                  .fontSize(12)
                  .fontColor(Theme.primary)
                  .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                  .backgroundColor('#E8F1FF')
                  .borderRadius(14)
              }
              .width('100%')

              Text(this.post!.title)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.textPrimary)
                .width('100%')

              Text(this.post!.content)
                .fontSize(14)
                .lineHeight(24)
                .fontColor(Theme.textSecondary)
                .width('100%')

              Row({ space: 16 }) {
                this.StatPill('点赞', String(this.post!.likeCount ?? 0))
                this.StatPill('评论', String(this.post!.commentCount ?? 0))
                this.StatPill('浏览', String(this.post!.viewCount ?? 0))
                Blank()
                Button('点赞')
                  .height(34)
                  .padding({ left: 16, right: 16 })
                  .backgroundColor('#FFEAF2')
                  .fontColor(Theme.accent)
                  .borderRadius(17)
                  .onClick(() => this.like())
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(24)
          }

          Column({ space: 12 }) {
            Text('评论区')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.textPrimary)
              .width('100%')

            if (this.replyTo) {
              Row() {
                Text(`正在回复 ${postAuthorLabel(this.replyTo.userId)}`)
                  .fontSize(12)
                  .fontColor(Theme.primary)
                Blank()
                Text('取消')
                  .fontSize(12)
                  .fontColor(Theme.textMuted)
                  .onClick(() => this.cancelReply())
              }
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor('#E8F1FF')
              .borderRadius(14)
            }

            Column({ space: 10 }) {
              TextArea({ placeholder: '写下你的想法…', text: this.commentText })
                .height(110)
                .backgroundColor('#F8FAFF')
                .border({ width: 1, color: Theme.border })
                .borderRadius(18)
                .padding(14)
                .fontSize(14)
                .onChange((value: string) => this.commentText = value)

              Button(this.submitting ? '发送中…' : '发表评论')
                .width('100%')
                .height(42)
                .backgroundColor(Theme.primary)
                .fontColor(Color.White)
                .borderRadius(16)
                .enabled(!this.submitting)
                .onClick(() => this.submitComment())
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(24)

            if (this.threads.length === 0 && !this.loading) {
              EmptyState({
                title: '还没有评论',
                description: '你可以成为第一个互动的人。'
              })
            } else {
              ForEach(this.threads, (thread: CommentThread) => {
                Column({ space: 10 }) {
                  Column({ space: 8 }) {
                    Row({ space: 10 }) {
                      Image(MediaAssets.avatar())
                        .width(34)
                        .height(34)
                        .borderRadius(17)
                      Column({ space: 4 }) {
                        Text(postAuthorLabel(thread.comment.userId))
                          .fontSize(13)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(Theme.textPrimary)
                        Text(relativeTime(thread.comment.createdAt))
                          .fontSize(11)
                          .fontColor(Theme.textMuted)
                      }
                      .layoutWeight(1)
                      Text(`赞 ${thread.comment.likeCount ?? 0}`)
                        .fontSize(11)
                        .fontColor(Theme.primary)
                    }
                    Text(thread.comment.content)
                      .fontSize(13)
                      .fontColor(Theme.textSecondary)
                      .lineHeight(20)
                      .width('100%')
                    Row() {
                      Blank()
                      Text('回复')
                        .fontSize(12)
                        .fontColor(Theme.primary)
                        .onClick(() => this.startReply(thread.comment))
                    }
                    .width('100%')
                  }
                  .width('100%')
                  .padding(14)
                  .backgroundColor('#FFFFFF')
                  .borderRadius(20)

                  if (thread.replies.length > 0) {
                    Column({ space: 8 }) {
                      ForEach(thread.replies, (reply: Comment) => {
                        Column({ space: 4 }) {
                          Row() {
                            Text(postAuthorLabel(reply.userId))
                              .fontSize(12)
                              .fontWeight(FontWeight.Medium)
                              .fontColor(Theme.textPrimary)
                            Blank()
                            Text(relativeTime(reply.createdAt))
                              .fontSize(11)
                              .fontColor(Theme.textMuted)
                          }
                          .width('100%')
                          Text(reply.content)
                            .fontSize(12)
                            .fontColor(Theme.textSecondary)
                            .lineHeight(18)
                        }
                        .padding(12)
                        .backgroundColor('#F6F7F8')
                        .borderRadius(16)
                      }, (reply: Comment) => String(reply.id))
                    }
                    .padding({ left: 18, right: 4, bottom: 4 })
                  }
                }
              }, (thread: CommentThread) => String(thread.comment.id))
            }
          }
          .width('100%')
        }
        .padding({ left: 16, right: 16, top: 16, bottom: 24 })
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.background)
  }

  @Builder private StatPill(label: string, value: string) {
    Column({ space: 2 }) {
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.textPrimary)
      Text(label)
        .fontSize(11)
        .fontColor(Theme.textMuted)
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#F8FAFF')
    .borderRadius(16)
    .alignItems(HorizontalAlign.Center)
  }
}
