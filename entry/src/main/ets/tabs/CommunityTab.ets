import { Api } from '../api/Api';
import { MediaAssets } from '../assets/MediaAssets';
import { EmptyState, OfflineBanner } from '../components/Ui';
import { normalizeKeyword, postAuthorLabel, relativeTime } from '../common/Formatters';
import { AppPrompt } from '../common/AppPrompt';
import { AppRouter } from '../common/AppRouter';
import { Theme } from '../common/Theme';
import { Post } from '../model/Models';
import { SessionStore } from '../store/SessionStore';
import { AppStatus } from '../app/AppStatus';

interface PostDetailParams {
  id?: number;
}

type CommunityMode = 'RECOMMEND' | 'MINE' | 'CARE' | 'SHOP' | 'LIFE';

@Component
export struct CommunityTab {
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private allPosts: Post[] = [];
  @State private visiblePosts: Post[] = [];
  @State private page: number = 0;
  @State private last: boolean = false;
  @State private keyword: string = '';
  @State private mode: CommunityMode = 'RECOMMEND';

  aboutToAppear(): void {
    if (this.allPosts.length === 0) {
      this.refresh();
    }
  }

  private async refresh(): Promise<void> {
    if (this.mode === 'MINE') {
      await this.loadMinePosts();
      return;
    }
    this.page = 0;
    this.last = false;
    await this.loadRecommend(true);
  }

  private async loadRecommend(reset: boolean): Promise<void> {
    this.loading = true;
    this.errorText = '';
    try {
      const nextPage = reset ? 0 : this.page;
      const res = await Api.getPosts(nextPage, 10);
      this.page = nextPage;
      this.last = res.last;
      this.allPosts = reset ? res.content : [...this.allPosts, ...res.content];
      this.applyFilters();
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private async loadMore(): Promise<void> {
    if (this.loading || this.last || this.mode === 'MINE') {
      return;
    }
    this.page += 1;
    await this.loadRecommend(false);
  }

  private async loadMinePosts(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      AppPrompt.toast('请先登录后查看我的帖子');
      AppRouter.push('pages/Login');
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      this.allPosts = await Api.getUserPosts(user.id);
      this.last = true;
      this.applyFilters();
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private async switchMode(mode: CommunityMode): Promise<void> {
    this.mode = mode;
    await this.refresh();
  }

  private inferCategory(post: Post): CommunityMode {
    const text = normalizeKeyword(`${post.title} ${post.content}`);
    if (text.indexOf('疫苗') >= 0 || text.indexOf('过敏') >= 0 || text.indexOf('体检') >= 0 || text.indexOf('医院') >= 0) {
      return 'CARE';
    }
    if (text.indexOf('特价') >= 0 || text.indexOf('新品') >= 0 || text.indexOf('喂食器') >= 0 || text.indexOf('套餐') >= 0 || text.indexOf('冻干') >= 0) {
      return 'SHOP';
    }
    if (text.indexOf('日常') >= 0 || text.indexOf('领养') >= 0 || text.indexOf('故事') >= 0 || text.indexOf('猫咪') >= 0 || text.indexOf('金毛') >= 0) {
      return 'LIFE';
    }
    return 'RECOMMEND';
  }

  private categoryLabel(post: Post): string {
    const category = this.inferCategory(post);
    if (category === 'CARE') {
      return '健康科普';
    }
    if (category === 'SHOP') {
      return '用品测评';
    }
    if (category === 'LIFE') {
      return '宠物日常';
    }
    return '精选推荐';
  }

  private applyFilters(): void {
    const keyword = normalizeKeyword(this.keyword);
    let result = [...this.allPosts];
    if (this.mode !== 'RECOMMEND' && this.mode !== 'MINE') {
      result = result.filter((post: Post) => this.inferCategory(post) === this.mode);
    }
    if (keyword) {
      result = result.filter((post: Post) => normalizeKeyword(`${post.title} ${post.content}`).indexOf(keyword) >= 0);
    }
    this.visiblePosts = result;
  }

  private openPost(post: Post): void {
    if (post.id) {
      AppRouter.push('pages/PostDetail', { id: post.id } as PostDetailParams);
    }
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(MediaAssets.heroDog())
          .width('100%')
          .height(168)
          .objectFit(ImageFit.Cover)
        Column()
          .width('100%')
          .height(168)
          .linearGradient({ angle: 180, colors: [['#0F172A10', 0], ['#0F172A36', 0.45], ['#F3F7FF', 1]] })

        Column({ space: 12 }) {
          Row({ space: 12 }) {
            Image(MediaAssets.avatar())
              .width(38)
              .height(38)
              .borderRadius(19)
            Column({ space: 4 }) {
              Text('城宠社区')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text('围绕健康科普、用品测评和宠物日常展开')
                .fontSize(11)
                .fontColor('#F8FAFC')
            }
            .layoutWeight(1)
            Image($r('app.media.hero_bell'))
              .width(22)
              .height(22)
          }
          .width('100%')

          Row({ space: 10 }) {
            Row({ space: 8 }) {
              Image($r('app.media.hero_search'))
                .width(18)
                .height(18)
              TextInput({ placeholder: '搜索帖子、医院经验、用品关键词', text: this.keyword })
                .layoutWeight(1)
                .height(40)
                .backgroundColor('transparent')
                .fontSize(14)
                .fontColor(Theme.textPrimary)
                .border({ width: 0 })
                .onChange((value: string) => {
                  this.keyword = value;
                  this.applyFilters();
                })
            }
            .layoutWeight(1)
            .height(40)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#FFFFFFF0')
            .borderRadius(20)

            Button('发帖')
              .height(40)
              .padding({ left: 14, right: 14 })
              .backgroundColor('#FFFFFFF0')
              .fontColor(Theme.primary)
              .borderRadius(20)
              .fontSize(12)
              .onClick(() => AppRouter.push('pages/NewPost'))
          }
          .width('100%')
        }
        .padding({ left: 16, right: 16, bottom: 10 })
        .width('100%')
      }

      Scroll() {
        Row({ space: 8 }) {
          this.ModeChip('推荐', 'RECOMMEND')
          this.ModeChip('我的', 'MINE')
          this.ModeChip('健康科普', 'CARE')
          this.ModeChip('用品测评', 'SHOP')
          this.ModeChip('宠物日常', 'LIFE')
        }
        .padding({ left: 16, right: 16, top: 10, bottom: 8 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      if (!AppStatus.isBackendOnline()) {
        OfflineBanner({ text: '当前为离线社区数据，分类与详情仍可完整浏览', action: () => this.refresh() })
          .padding({ left: 16, right: 16, bottom: 8 })
      }

      if (this.errorText) {
        Text(this.errorText)
          .fontSize(13)
          .fontColor('#D14343')
          .padding({ left: 16, right: 16, bottom: 8 })
      }

      if (!this.errorText && !this.loading && this.visiblePosts.length === 0) {
        EmptyState({
          title: '没有匹配的帖子',
          description: '切换分类或者发布一条新的宠物帖子。',
          actionText: '去发帖',
          action: () => AppRouter.push('pages/NewPost')
        })
      } else {
        List() {
          ForEach(this.visiblePosts, (post: Post) => {
            ListItem() {
              Column({ space: 12 }) {
                Row({ space: 10 }) {
                  Image(MediaAssets.avatar())
                    .width(42)
                    .height(42)
                    .borderRadius(21)
                  Column({ space: 4 }) {
                    Text(postAuthorLabel(post.userId))
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Theme.textPrimary)
                    Text(relativeTime(post.createdAt))
                      .fontSize(11)
                      .fontColor(Theme.textMuted)
                  }
                  .layoutWeight(1)
                  Text(this.categoryLabel(post))
                    .fontSize(11)
                    .fontColor(Theme.primary)
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .backgroundColor('#E8F1FF')
                    .borderRadius(14)
                }

                Text(post.title)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.textPrimary)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')

                Text(post.content)
                  .fontSize(13)
                  .fontColor(Theme.textSecondary)
                  .lineHeight(22)
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')

                Image(MediaAssets.postImage(post.imageUrls, post.id ?? 0))
                  .width('100%')
                  .height(176)
                  .borderRadius(20)
                  .objectFit(ImageFit.Cover)

                Row({ space: 18 }) {
                  Row({ space: 6 }) {
                    Image($r('app.media.heart')).width(16).height(16)
                    Text(String(post.likeCount ?? 0)).fontSize(12).fontColor(Theme.textSecondary)
                  }
                  Row({ space: 6 }) {
                    Image($r('app.media.tiezi')).width(16).height(16)
                    Text(String(post.commentCount ?? 0)).fontSize(12).fontColor(Theme.textSecondary)
                  }
                  Row({ space: 6 }) {
                    Image($r('app.media.view')).width(16).height(16)
                    Text(String(post.viewCount ?? 0)).fontSize(12).fontColor(Theme.textSecondary)
                  }
                  Blank()
                  Button('查看详情')
                    .height(32)
                    .padding({ left: 14, right: 14 })
                    .fontSize(12)
                    .backgroundColor('#E8F1FF')
                    .fontColor(Theme.primary)
                    .borderRadius(16)
                    .onClick(() => this.openPost(post))
                }
                .width('100%')
              }
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(24)
            }
            .padding({ left: 16, right: 16, bottom: 14 })
            .onClick(() => this.openPost(post))
          }, (post: Post) => String(post.id))

          ListItem() {
            Column({ space: 8 }) {
              if (!this.last && this.mode !== 'MINE' && !this.loading) {
                Button('加载更多')
                  .height(34)
                  .padding({ left: 18, right: 18 })
                  .backgroundColor('#E8F1FF')
                  .fontColor(Theme.primary)
                  .borderRadius(17)
                  .fontSize(12)
                  .onClick(() => this.loadMore())
              } else {
                Text(this.loading ? '加载中…' : '已经到底啦')
                  .fontSize(12)
                  .fontColor(Theme.textMuted)
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 20 })
            .alignItems(HorizontalAlign.Center)
          }
        }
        .layoutWeight(1)
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }

  @Builder private ModeChip(label: string, mode: CommunityMode) {
    Text(label)
      .fontSize(12)
      .fontColor(this.mode === mode ? Color.White : Theme.textSecondary)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(this.mode === mode ? Theme.primary : '#FFFFFF')
      .borderRadius(16)
      .onClick(() => this.switchMode(mode))
  }
}
