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
    Column() {
      // 蓝色顶部区域
      Column({ space: 12 }) {
        // 顶部操作栏
        Row({ space: 12 }) {
          // 用户头像
          Image($r('app.media.people'))
            .width(40)
            .height(40)
            .borderRadius(20)

          // 搜索栏
          Row() {
            Image($r('app.media.fangdajing'))
              .width(16)
              .height(16)
              .fillColor('#666')
              .margin({ left: 12 })
            TextInput({ placeholder: '搜索帖子/话题/用户' })
              .layoutWeight(1)
              .height(36)
              .backgroundColor('transparent')
              .fontSize(14)
              .border({ width: 0 })
          }
          .layoutWeight(1)
          .height(36)
          .padding({ right: 12 })
          .backgroundColor(Color.White)
          .borderRadius(18)

          // 更多按钮
          Image($r('app.media.more'))
            .width(24)
            .height(24)
            .fillColor('#333')
        }
        .padding({ left: 16, right: 16 })

        // 三个圆形按钮
        Row({ space: 30 }) {
          Column({ space: 4 }) {
            Stack() {
              Circle()
                .width(50)
                .height(50)
                .fill('#E0EAFF')
              Image($r('app.media.tiezi'))
                .width(24)
                .height(24)
                .fillColor('#2B7FFF')
            }
            Text('我的帖子')
              .fontSize(12)
              .fontColor(Color.White)
          }
          .alignItems(HorizontalAlign.Center)

          Column({ space: 4 }) {
            Stack() {
              Circle()
                .width(50)
                .height(50)
                .fill('#E0EAFF')
              Image($r('app.media.weiyang'))
                .width(24)
                .height(24)
                .fillColor('#2B7FFF')
            }
            Text('喂养')
              .fontSize(12)
              .fontColor(Color.White)
          }
          .alignItems(HorizontalAlign.Center)

          Column({ space: 4 }) {
            Stack() {
              Circle()
                .width(50)
                .height(50)
                .fill('#E0EAFF')
              Image($r('app.media.guanzhu'))
                .width(24)
                .height(24)
                .fillColor('#2B7FFF')
            }
            Text('我的关注')
              .fontSize(12)
              .fontColor(Color.White)
          }
          .alignItems(HorizontalAlign.Center)

          Blank()
        }
        .padding({ left: 16, right: 16, bottom: 12 })
      }
      .width('100%')
      .backgroundColor('#E8F4FF')
      .padding({ top: 12 })

      // 内容区域
      if (!AppStatus.isBackendOnline()) {
        OfflineBanner({ action: () => router.pushUrl({ url: 'pages/Login' }) })
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      }

      if (this.errorText) {
        Text(this.errorText)
          .fontSize(13)
          .fontColor(Color.Red)
          .padding(16)
      }

      // 帖子列表
      List() {
        ForEach(this.posts, (post: Post) => {
          ListItem() {
            Column({ space: 8 }) {
              // 头部：头像 + 标题 + 菜单
              Row({ space: 8 }) {
                Stack() {
                  Circle()
                    .width(40)
                    .height(40)
                    .fill('#B3D9FF')
                }

                Column({ space: 2 }) {
                  Text(post.title ?? '')
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text('发布于2小时前')
                    .fontSize(11)
                    .fontColor('#999')
                }
                .layoutWeight(1)

                Text('...')
                  .fontSize(16)
                  .fontColor('#999')
              }

              // 内容图片
              if (post.imageUrls) {
                Image(post.imageUrls)
                  .width('100%')
                  .height(180)
                  .borderRadius(8)
                  .objectFit(ImageFit.Cover)
              }

              // 互动数据
              Row({ space: 12 }) {
                Text(`❤️ ${post.likeCount ?? 0}`)
                  .fontSize(12)
                  .fontColor('#999')
                Text(`💬 ${post.commentCount ?? 0}`)
                  .fontSize(12)
                  .fontColor('#999')
                Text(`👁️ ${post.viewCount ?? 0}`)
                  .fontSize(12)
                  .fontColor('#999')
                Blank()
                Text('查看详情')
                  .fontSize(12)
                  .fontColor('#2B7FFF')
                  .fontWeight(FontWeight.Bold)
              }
            }
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
          }
          .padding({ left: 16, right: 16, bottom: 12 })
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
              .fontColor('#999')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(12)
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
      .layoutWeight(1)
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
