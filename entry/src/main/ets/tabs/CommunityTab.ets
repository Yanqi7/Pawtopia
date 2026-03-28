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

  build() {
    Stack() {
      Column() {
        // Top header with avatar, search, more
        Row({ space: 10 }) {
          Image($r('app.media.people'))
            .width(40)
            .height(40)
            .borderRadius(20)
          TextInput({ placeholder: '搜索帖子/话题/用户' })
            .layoutWeight(1)
            .height(36)
            .backgroundColor('#F0F2F5')
            .borderRadius(18)
            .padding({ left: 12, right: 12 })
          Image($r('app.media.more'))
            .width(24)
            .height(24)
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })

        // Action icons
        Row({ space: 30 }) {
          Column({ space: 4 }) {
            Image($r('app.media.tiezi')).width(40).height(40).borderRadius(20).backgroundColor('#E8F4FF')
            Text('我的帖子').fontSize(11).fontColor('#666')
          }.alignItems(HorizontalAlign.Center)
          Column({ space: 4 }) {
            Image($r('app.media.weiyang')).width(40).height(40).borderRadius(20).backgroundColor('#E8F4FF')
            Text('喂养').fontSize(11).fontColor('#666')
          }.alignItems(HorizontalAlign.Center)
          Column({ space: 4 }) {
            Image($r('app.media.guanzhu')).width(40).height(40).borderRadius(20).backgroundColor('#E8F4FF')
            Text('我的关注').fontSize(11).fontColor('#666')
          }.alignItems(HorizontalAlign.Center)
          Blank()
        }
        .padding({ left: 16, right: 16, bottom: 12 })

        if (!AppStatus.isBackendOnline()) {
          OfflineBanner({ action: () => router.pushUrl({ url: 'pages/Login' }) })
            .padding({ left: 16, right: 16, bottom: 10 })
        }

        if (this.errorText) {
          Text(this.errorText).fontSize(13).fontColor(Color.Red).padding(16)
        }

        // Posts list
        List() {
          ForEach(this.posts, (post: Post) => {
            ListItem() {
              Column({ space: 8 }) {
                // Post header
                Row({ space: 8 }) {
                  Image($r('app.media.people')).width(32).height(32).borderRadius(16)
                  Column({ space: 2 }) {
                    Text(post.title).fontSize(14).fontWeight(FontWeight.Medium).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text('2小时前').fontSize(11).fontColor('#999')
                  }.layoutWeight(1)
                  Text('...').fontSize(16).fontColor('#999')
                }

                // Post content with image
                if (post.imageUrls) {
                  Image(post.imageUrls)
                    .width('100%')
                    .height(180)
                    .borderRadius(8)
                    .objectFit(ImageFit.Cover)
                }

                // Engagement stats
                Row({ space: 12 }) {
                  Text(`👍 ${post.likeCount ?? 0}`).fontSize(12).fontColor('#999')
                  Text(`💬 ${post.commentCount ?? 0}`).fontSize(12).fontColor('#999')
                  Text(`👁 ${post.viewCount ?? 0}`).fontSize(12).fontColor('#999')
                  Blank()
                  Text('查看详情').fontSize(12).fontColor('#2B7FFF')
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

      // Floating action button
      Column() {
        Blank()
        Row() {
          Blank()
          Button()
            .width(56)
            .height(56)
            .borderRadius(28)
            .backgroundColor('#2B7FFF')
            .onClick(() => router.pushUrl({ url: 'pages/NewPost' }))
            .overlay(
              Text('+')
                .fontSize(28)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Bold),
              Alignment.Center
            )
        }
        .padding({ right: 16, bottom: 80 })
        .width('100%')
      }
      .height('100%')
      .width('100%')
    }
    .height('100%')
    .width('100%')
  }
}
