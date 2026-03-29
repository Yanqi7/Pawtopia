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
        // Top header with search
        Row({ space: 8 }) {
          TextInput({ placeholder: '搜索帖子/话题/用户' })
            .layoutWeight(1)
            .height(36)
            .padding({ left: 12, right: 12 })
            .borderRadius(18)
            .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
            .border({ width: 1, color: $r('sys.color.ohos_id_color_border') })
          Image($r('app.media.more'))
            .width(24)
            .height(24)
            .fillColor($r('sys.color.ohos_id_color_text_secondary'))
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })

        // Action row
        Row({ space: 20 }) {
          Column({ space: 6 }) {
            Stack() {
              Circle()
                .width(44)
                .height(44)
                .fill($r('sys.color.ohos_id_color_button_normal'))
              Image($r('app.media.tiezi'))
                .width(20)
                .height(20)
                .fillColor($r('sys.color.ohos_id_color_brand'))
            }
            Text('我的帖子').fontSize(10).fontColor($r('sys.color.ohos_id_color_text_secondary'))
          }
          .alignItems(HorizontalAlign.Center)

          Column({ space: 6 }) {
            Stack() {
              Circle()
                .width(44)
                .height(44)
                .fill($r('sys.color.ohos_id_color_button_normal'))
              Image($r('app.media.weiyang'))
                .width(20)
                .height(20)
                .fillColor($r('sys.color.ohos_id_color_brand'))
            }
            Text('喂养').fontSize(10).fontColor($r('sys.color.ohos_id_color_text_secondary'))
          }
          .alignItems(HorizontalAlign.Center)

          Column({ space: 6 }) {
            Stack() {
              Circle()
                .width(44)
                .height(44)
                .fill($r('sys.color.ohos_id_color_button_normal'))
              Image($r('app.media.guanzhu'))
                .width(20)
                .height(20)
                .fillColor($r('sys.color.ohos_id_color_brand'))
            }
            Text('我的关注').fontSize(10).fontColor($r('sys.color.ohos_id_color_text_secondary'))
          }
          .alignItems(HorizontalAlign.Center)

          Blank()
        }
        .padding({ left: 16, right: 16, bottom: 12 })

        if (!AppStatus.isBackendOnline()) {
          OfflineBanner({ action: () => router.pushUrl({ url: 'pages/Login' }) })
            .padding({ left: 16, right: 16, bottom: 10 })
        }

        if (this.errorText) {
          Text(this.errorText)
            .fontSize(13)
            .fontColor($r('sys.color.ohos_id_color_text_warning'))
            .padding(16)
        }

        // Posts list
        List() {
          ForEach(this.posts, (post: Post) => {
            ListItem() {
              Column({ space: 8 }) {
                Row({ space: 8 }) {
                  Image($r('app.media.people')).width(32).height(32).borderRadius(16)
                  Column({ space: 2 }) {
                    Text(post.title)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text('2小时前')
                      .fontSize(11)
                      .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
                  }
                  .layoutWeight(1)
                  Text('…')
                    .fontSize(16)
                    .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
                }

                if (post.imageUrls) {
                  Image(post.imageUrls)
                    .width('100%')
                    .height(160)
                    .borderRadius(8)
                    .objectFit(ImageFit.Cover)
                }

                Row({ space: 12 }) {
                  Text(`👍 ${post.likeCount ?? 0}`).fontSize(12).fontColor($r('sys.color.ohos_id_color_text_tertiary'))
                  Text(`💬 ${post.commentCount ?? 0}`).fontSize(12).fontColor($r('sys.color.ohos_id_color_text_tertiary'))
                  Text(`👁 ${post.viewCount ?? 0}`).fontSize(12).fontColor($r('sys.color.ohos_id_color_text_tertiary'))
                  Blank()
                  Text('查看详情')
                    .fontSize(12)
                    .fontColor($r('sys.color.ohos_id_color_brand'))
                }
              }
              .padding(12)
              .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
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
              Text('没有更多了')
                .fontSize(12)
                .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(12)
            } else {
              Text(this.loading ? '加载中…' : '上拉加载更多')
                .fontSize(12)
                .fontColor($r('sys.color.ohos_id_color_text_tertiary'))
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
          Stack() {
            Button()
              .width(56)
              .height(56)
              .borderRadius(28)
              .backgroundColor($r('sys.color.ohos_id_color_brand'))
              .onClick(() => router.pushUrl({ url: 'pages/NewPost' }))
            Text('+')
              .fontSize(28)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .align(Alignment.Center)
          }
          .width(56)
          .height(56)
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
