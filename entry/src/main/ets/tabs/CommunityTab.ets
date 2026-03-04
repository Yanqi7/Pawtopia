import router from '@ohos.router';
import { Api } from '../api/Api';
import { Post } from '../model/Models';
import { AppStatus } from '../app/AppStatus';
import { OfflineBanner } from '../components/Ui';

@Component
export struct CommunityTab {
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private posts: Post[] = [];
  @State private page: number = 0;
  @State private last: boolean = false;

  aboutToAppear(): void {
    if (this.posts.length === 0) {
      this.refresh();
    }
  }

  private async refresh(): Promise<void> {
    this.page = 0;
    this.last = false;
    await this.loadPage(true);
  }

  private async loadMore(): Promise<void> {
    if (this.loading || this.last) {
      return;
    }
    this.page += 1;
    await this.loadPage(false);
  }

  private async loadPage(reset: boolean): Promise<void> {
    this.loading = true;
    this.errorText = '';
    try {
      const res = await Api.getPosts(this.page, 10);
      this.last = res.last;
      this.posts = reset ? res.content : [...this.posts, ...res.content];
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private likesCount(): number {
    return this.posts.reduce((sum, p) => sum + (p.likeCount ?? 0), 0);
  }

  build() {
    Column() {
      Column({ space: 10 }) {
        Row() {
          Column({ space: 2 }) {
            Text('社区')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
            Text('看看大家都在分享什么')
              .fontSize(12)
              .fontColor('#888')
          }
          Blank()
          Button(this.loading ? '刷新中…' : '刷新')
            .height(32)
            .borderRadius(16)
            .backgroundColor('#F0F2F5')
            .onClick(() => this.refresh())
          Button('发布')
            .height(32)
            .borderRadius(16)
            .backgroundColor('#2B7FFF')
            .fontColor(Color.White)
            .onClick(() => router.pushUrl({ url: 'pages/NewPost' }))
        }
        .padding({ left: 16, right: 16, top: 14 })

        Row({ space: 12 }) {
          Column({ space: 4 }) {
            Text('动态数量').fontSize(11).fontColor('#888')
            Text(`${this.posts.length} 条`).fontSize(16).fontWeight(FontWeight.Medium)
          }.layoutWeight(1)
          Column({ space: 4 }) {
            Text('本页互动').fontSize(11).fontColor('#888')
            Text(`${this.likesCount()} 次`).fontSize(16).fontWeight(FontWeight.Medium)
          }.layoutWeight(1)
          Column({ space: 4 }) {
            Text('最新更新').fontSize(11).fontColor('#888')
            Text('刚刚').fontSize(16).fontWeight(FontWeight.Medium)
          }.layoutWeight(1)
        }
        .padding(12)
        .backgroundColor('#F6F7F9')
        .borderRadius(12)
        .margin({ left: 16, right: 16, bottom: 6 })
      }

      if (!AppStatus.isBackendOnline()) {
        OfflineBanner({ action: () => router.pushUrl({ url: 'pages/Login' }) })
          .padding({ left: 16, right: 16, bottom: 10 })
      }

      if (this.errorText) {
        Text(this.errorText).fontSize(13).fontColor(Color.Red).padding({ left: 16, right: 16, bottom: 8 })
      }

      List() {
        ForEach(this.posts, (post: Post) => {
          ListItem() {
            Column({ space: 6 }) {
              Text(post.title).fontSize(16).fontWeight(FontWeight.Medium).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(post.content)
                .fontSize(13)
                .fontColor('#666')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Row({ space: 10 }) {
                Text(`👍 ${post.likeCount ?? 0}`).fontSize(12).fontColor('#999')
                Text(`💬 ${post.commentCount ?? 0}`).fontSize(12).fontColor('#999')
                Text(`👁 ${post.viewCount ?? 0}`).fontSize(12).fontColor('#999')
                Blank()
                Text('查看详情')
                  .fontSize(12)
                  .fontColor('#2B7FFF')
              }
            }
            .padding(12)
            .backgroundColor('#F6F7F9')
            .borderRadius(12)
          }
          .padding({ left: 16, right: 16, bottom: 10 })
          .onClick(() => {
            if (post.id) {
              router.pushUrl({ url: 'pages/PostDetail', params: { id: post.id } });
            }
          })
        }, (post: Post) => String(post.id))

        ListItem() {
          if (this.last) {
            Text('没有更多了').fontSize(12).fontColor('#999').width('100%').textAlign(TextAlign.Center).padding(12)
          } else {
            Text(this.loading ? '加载中…' : '上拉加载更多')
              .fontSize(12)
              .fontColor('#999')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(12)
          }
        }
      }
      .onReachEnd(() => this.loadMore())
    }
    .height('100%')
    .width('100%')
  }
}
