import { Api } from '../api/Api';
import { MediaAssets } from '../assets/MediaAssets';
import {
  EmptyState,
  OfflineBanner,
  PostCard,
  SearchBar,
  SectionHeader
} from '../components/Ui';
import { normalizeKeyword } from '../common/Formatters';
import { AppPrompt } from '../common/AppPrompt';
import { AppRouter } from '../common/AppRouter';
import { Theme } from '../common/Theme';
import { Post } from '../model/Models';
import { SessionStore } from '../store/SessionStore';
import { AppStatus } from '../app/AppStatus';

interface PostDetailParams {
  id?: number;
}

interface EditPostParams {
  postId?: number;
}

type CommunityMode = 'RECOMMEND' | 'MINE' | 'CARE' | 'SHOP' | 'LIFE';

@Component
export struct CommunityTab {
  initialMode: CommunityMode = 'RECOMMEND';
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private allPosts: Post[] = [];
  @State private visiblePosts: Post[] = [];
  @State private page: number = 0;
  @State private last: boolean = false;
  @State private keyword: string = '';
  @State private mode: CommunityMode = 'RECOMMEND';

  aboutToAppear(): void {
    AppRouter.bind(this);
    const modeChanged = this.mode !== this.initialMode;
    if (modeChanged) {
      this.mode = this.initialMode;
      this.keyword = '';
      this.allPosts = [];
      this.visiblePosts = [];
      this.page = 0;
      this.last = false;
    }
    if (this.allPosts.length === 0 || modeChanged) {
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
      AppPrompt.toast('请先登录后查看我的帖子', this);
      AppRouter.push('pages/Login', undefined, this);
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
      AppRouter.push('pages/PostDetail', { id: post.id } as PostDetailParams, this);
    }
  }

  private async like(post: Post): Promise<void> {
    if (!post.id) {
      return;
    }
    try {
      const updated = await Api.likePost(post.id);
      this.allPosts = this.allPosts.map((item: Post): Post => {
        if (item.id !== post.id) {
          return item;
        }
        return {
          id: item.id,
          title: item.title,
          content: item.content,
          userId: item.userId,
          petId: item.petId,
          imageUrls: item.imageUrls,
          viewCount: item.viewCount,
          likeCount: updated.likeCount ?? item.likeCount,
          commentCount: item.commentCount,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt
        } as Post;
      });
      this.applyFilters();
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '点赞失败';
    }
  }

  private editPost(post: Post): void {
    if (!post.id) {
      return;
    }
    AppRouter.push('pages/NewPost', { postId: post.id } as EditPostParams, this);
  }

  private async deletePost(post: Post): Promise<void> {
    if (!post.id) {
      return;
    }
    try {
      await Api.deletePost(post.id);
      this.allPosts = this.allPosts.filter((item: Post) => item.id !== post.id);
      this.applyFilters();
      AppPrompt.toast('帖子已删除', this);
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '删除失败';
    }
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(MediaAssets.heroDog())
          .width('100%')
          .height(176)
          .objectFit(ImageFit.Cover)
        Column()
          .width('100%')
          .height(176)
          .linearGradient({ angle: 180, colors: [['#0F172A10', 0], ['#0F172A52', 0.52], ['#F4F8FF', 1]] })
        Column({ space: 10 }) {
          Text('Pawtopia 社区')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          SearchBar({
            value: this.keyword,
            placeholder: '搜索帖子、医院经验、用品关键词',
            actionText: '搜索',
            onChange: (value: string) => {
              this.keyword = value;
              this.applyFilters();
            },
            onSubmit: () => this.applyFilters()
          })
        }
        .padding({ left: 16, right: 16, bottom: 14 })
        .width('100%')
      }

      Scroll() {
        Column({ space: 14 }) {
          Scroll() {
            Row({ space: 8 }) {
              this.ModeChip('推荐', 'RECOMMEND')
              this.ModeChip('我的', 'MINE')
              this.ModeChip('健康科普', 'CARE')
              this.ModeChip('用品测评', 'SHOP')
              this.ModeChip('宠物日常', 'LIFE')
            }
            .padding({ bottom: 6 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)

          if (!AppStatus.isBackendOnline()) {
            OfflineBanner({ text: '当前无法连接服务，社区内容可能不是最新状态', action: () => this.refresh() })
          }

          if (this.errorText) {
            Text(this.errorText)
              .fontSize(13)
              .fontColor(Theme.danger)
              .width('100%')
          }

          SectionHeader({
            title: this.mode === 'MINE' ? '我的帖子' : '帖子列表',
            actionText: this.mode === 'MINE' ? '发帖' : '刷新',
            onAction: () => this.mode === 'MINE' ? AppRouter.push('pages/NewPost', undefined, this) : this.refresh()
          })

          if (!this.errorText && !this.loading && this.visiblePosts.length === 0) {
            EmptyState({
              title: '没有匹配的帖子',
              description: '切换分类或者发布一条新的宠物帖子。',
              actionText: '去发帖',
              action: () => AppRouter.push('pages/NewPost', undefined, this)
            })
          } else {
            ForEach(this.visiblePosts, (post: Post) => {
              PostCard({
                post: post,
                categoryLabel: this.categoryLabel(post),
                showManageActions: this.mode === 'MINE',
                onTap: () => this.openPost(post),
                onLike: () => { this.like(post); },
                onEdit: () => this.editPost(post),
                onDelete: () => { this.deletePost(post); }
              })
            }, (post: Post) => String(post.id))

            Column({ space: 8 }) {
              if (!this.last && this.mode !== 'MINE' && !this.loading) {
                Button('加载更多')
                  .height(34)
                  .padding({ left: 18, right: 18 })
                  .backgroundColor(Theme.primarySoft)
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
            .padding({ top: 4, bottom: 6 })
            .alignItems(HorizontalAlign.Center)
          }
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 24 })
        .width('100%')
      }
      .layoutWeight(1)
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
      .backgroundColor(this.mode === mode ? Theme.primary : Theme.surface)
      .borderRadius(16)
      .onClick(() => this.switchMode(mode))
  }
}
