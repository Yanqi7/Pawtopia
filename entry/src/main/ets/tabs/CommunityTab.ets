import { Api } from '../api/Api';
import { MediaAssets } from '../assets/MediaAssets';
import { EmptyState, OfflineBanner } from '../components/Ui';
import { normalizeKeyword, postAuthorLabel, relativeTime } from '../common/Formatters';
import { AppPrompt } from '../common/AppPrompt';
import { AppRouter } from '../common/AppRouter';
import { Theme } from '../common/Theme';
import { Post } from '../model/Models';
import { SessionStore } from '../store/SessionStore';

interface PostDetailParams {
  id?: number;
}

type CommunityMode = 'RECOMMEND' | 'MINE' | 'FEED';

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
    if (this.loading || this.last || this.mode !== 'RECOMMEND') {
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
    if (this.mode === mode && mode !== 'FEED') {
      return;
    }
    this.mode = mode;
    if (mode === 'FEED') {
      if (this.allPosts.length === 0) {
        await this.refresh();
      }
      this.applyFilters();
      return;
    }
    await this.refresh();
  }

  private applyFilters(): void {
    const keyword = normalizeKeyword(this.keyword);
    let result = [...this.allPosts];
    if (this.mode === 'FEED') {
      result = result.filter((post: Post) => this.containsText(post, '喂养') || this.containsText(post, '狗粮') || this.containsText(post, '猫粮'));
    }
    if (keyword) {
      result = result.filter((post: Post) => {
        return normalizeKeyword(post.title).indexOf(keyword) >= 0 || normalizeKeyword(post.content).indexOf(keyword) >= 0;
      });
    }
    this.visiblePosts = result;
  }

  private containsText(post: Post, keyword: string): boolean {
    const text = `${post.title} ${post.content}`.toLowerCase();
    return text.indexOf(keyword.toLowerCase()) >= 0;
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
          .height(220)
          .objectFit(ImageFit.Cover)
        Column()
          .width('100%')
          .height(220)
          .linearGradient({
            angle: 180,
            colors: [['#0F172A10', 0], ['#0F172A40', 0.45], ['#F3F7FF', 1]]
          })

        Column({ space: 14 }) {
          Row({ space: 12 }) {
            Image(MediaAssets.avatar())
              .width(42)
              .height(42)
              .borderRadius(21)
            Column({ space: 4 }) {
              Text('Pawtopia 社区')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text('分享日常、学习喂养知识、记录宠物故事')
                .fontSize(12)
                .fontColor('#F8FAFC')
            }
            .layoutWeight(1)
            Image($r('app.media.hero_bell'))
              .width(26)
              .height(26)
          }
          .width('100%')

          Row({ space: 10 }) {
            Row({ space: 8 }) {
              Image($r('app.media.hero_search'))
                .width(18)
                .height(18)
              TextInput({ placeholder: '搜索帖子、标题或关键字', text: this.keyword })
                .layoutWeight(1)
                .height(42)
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
            .height(42)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#FFFFFFF0')
            .borderRadius(21)

            Button()
              .width(42)
              .height(42)
              .borderRadius(21)
              .backgroundColor('#FFFFFFF0')
              .onClick(() => AppRouter.push('pages/NewPost'))
            Image($r('app.media.hero_compose'))
              .width(22)
              .height(22)
          }
          .width('100%')
        }
        .padding({ left: 16, right: 16, bottom: 18 })
        .width('100%')
      }

      Row({ space: 12 }) {
        this.ActionCard('发帖', '开始分享', $r('app.media.hero_compose'), '#FFEAF2', () => AppRouter.push('pages/NewPost'))
        this.ActionCard('我的帖子', '查看你的内容', $r('app.media.hero_follow'), '#FFF5EC', () => this.switchMode('MINE'))
        this.ActionCard('喂养知识', '筛选教程', $r('app.media.hero_feed'), '#EEFFF3', () => this.switchMode('FEED'))
      }
      .padding({ left: 16, right: 16, top: 12 })
      .width('100%')

      Row({ space: 8 }) {
        this.ModeChip('推荐', 'RECOMMEND')
        this.ModeChip('我的', 'MINE')
        this.ModeChip('喂养', 'FEED')
        Blank()
        Button('刷新')
          .height(30)
          .backgroundColor('#E8F1FF')
          .fontColor(Theme.primary)
          .borderRadius(15)
          .fontSize(12)
          .onClick(() => this.refresh())
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .width('100%')

      if (!this.errorText && !this.loading && this.visiblePosts.length === 0) {
        EmptyState({
          title: this.mode === 'MINE' ? '你还没有发布内容' : '暂时没有匹配内容',
          description: this.mode === 'FEED' ? '试试切换回推荐页，或者发布你的第一条宠物日记。' : '换个关键词再试，或者发布新的宠物动态。',
          actionText: '去发帖',
          action: () => AppRouter.push('pages/NewPost')
        })
      } else {
        if (!this.errorText && this.loading && this.visiblePosts.length === 0) {
          Column({ space: 10 }) {
            LoadingProgress()
              .width(24)
              .height(24)
              .color(Theme.primary)
            Text('正在加载社区内容…')
              .fontSize(13)
              .fontColor(Theme.textSecondary)
          }
          .width('100%')
          .padding(24)
          .alignItems(HorizontalAlign.Center)
        }

        if (!this.errorText && this.visiblePosts.length > 0) {
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
                    Text(post.id ? `#${post.id}` : '#')
                      .fontSize(12)
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
                    .height(190)
                    .borderRadius(20)
                    .objectFit(ImageFit.Cover)

                  Row({ space: 18 }) {
                    Row({ space: 6 }) {
                      Image($r('app.media.heart'))
                        .width(16)
                        .height(16)
                      Text(String(post.likeCount ?? 0))
                        .fontSize(12)
                        .fontColor(Theme.textSecondary)
                    }
                    Row({ space: 6 }) {
                      Image($r('app.media.tiezi'))
                        .width(16)
                        .height(16)
                      Text(String(post.commentCount ?? 0))
                        .fontSize(12)
                        .fontColor(Theme.textSecondary)
                    }
                    Row({ space: 6 }) {
                      Image($r('app.media.view'))
                        .width(16)
                        .height(16)
                      Text(String(post.viewCount ?? 0))
                        .fontSize(12)
                        .fontColor(Theme.textSecondary)
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
                .backgroundColor('#FFFFFF')
                .borderRadius(24)
              }
              .padding({ left: 16, right: 16, bottom: 14 })
              .onClick(() => this.openPost(post))
            }, (post: Post) => String(post.id))

            ListItem() {
              Column({ space: 8 }) {
                if (this.errorText) {
                  Text(this.errorText)
                    .fontSize(12)
                    .fontColor('#D14343')
                } else {
                  Text(this.last || this.mode !== 'RECOMMEND' ? '已经到底啦' : (this.loading ? '加载中…' : '上拉加载更多'))
                    .fontSize(12)
                    .fontColor(Theme.textMuted)
                }
                if (!this.last && this.mode === 'RECOMMEND' && !this.loading) {
                  OfflineBanner({ text: '继续浏览更多宠物故事', action: () => this.loadMore() })
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, bottom: 20 })
            }
          }
          .onReachEnd(() => this.loadMore())
          .layoutWeight(1)
        }
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }

  @Builder private ActionCard(title: string, subTitle: string, icon: Resource, bgColor: string, action: () => void) {
    Column({ space: 8 }) {
      Image(icon)
        .width(28)
        .height(28)
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(Theme.textPrimary)
      Text(subTitle)
        .fontSize(11)
        .fontColor(Theme.textSecondary)
    }
    .width('33%')
    .height(108)
    .padding(12)
    .backgroundColor(bgColor)
    .borderRadius(20)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => action())
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
