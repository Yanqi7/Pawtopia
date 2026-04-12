import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Pet } from '../model/Models';
import { SessionStore } from '../store/SessionStore';
import { AppStatus } from '../app/AppStatus';
import { EmptyState, OfflineBanner, PetCard, SearchBar, SectionHeader } from '../components/Ui';
import { MediaAssets } from '../assets/MediaAssets';
import { normalizeKeyword } from '../common/Formatters';
import { Theme } from '../common/Theme';

interface NewPetParams {
  mode?: string;
}

interface PetDetailParams {
  id?: number;
}

interface MyAdoptionsParams {
  mode?: 'MINE' | 'OWNED';
}

type AdoptFilter = 'ALL' | 'MINE';

@Component
export struct AdoptTab {
  initialFilter: AdoptFilter = 'ALL';
  @State private filter: AdoptFilter = 'ALL';
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private pets: Pet[] = [];
  @State private keyword: string = '';

  aboutToAppear(): void {
    AppRouter.bind(this);
    const filterChanged = this.filter !== this.initialFilter;
    if (filterChanged) {
      this.filter = this.initialFilter;
      this.keyword = '';
      this.pets = [];
    }
    this.reload();
  }

  private async reload(): Promise<void> {
    const user = SessionStore.getUser();
    this.loading = true;
    this.errorText = '';
    try {
      const all = await Api.getAdoptionListings();
      if (user && user.id && this.filter === 'MINE') {
        this.pets = all.filter((pet: Pet) => pet.ownerId === user.id);
      } else {
        this.pets = all;
      }
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private visiblePets(): Pet[] {
    const keyword = normalizeKeyword(this.keyword);
    return this.pets.filter((pet: Pet) => {
      if (!keyword) {
        return true;
      }
      return normalizeKeyword(`${pet.name} ${pet.species} ${pet.breed ?? ''} ${pet.adoptionCity ?? ''} ${pet.description ?? ''}`).indexOf(keyword) >= 0;
    });
  }

  private openDetail(pet?: Pet): void {
    if (!pet?.id) {
      return;
    }
    AppRouter.push('pages/PetDetail', { id: pet.id } as PetDetailParams, this);
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(MediaAssets.adoptHero())
          .width('100%')
          .height(176)
          .objectFit(ImageFit.Cover)
        Column()
          .width('100%')
          .height(176)
          .linearGradient({ angle: 180, colors: [['#0F172A10', 0], ['#0F172A55', 0.5], ['#F4F8FF', 1]] })
        Column({ space: 10 }) {
          Text('给它一个家')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          SearchBar({
            value: this.keyword,
            placeholder: '搜索城市、品种、年龄或宠物名',
            actionText: '搜索',
            onChange: (value: string) => this.keyword = value,
            onSubmit: () => {}
          })
          Scroll() {
            Row({ space: 8 }) {
              this.FilterChip('全部', 'ALL')
              this.FilterChip('我发布的', 'MINE')
              Text('我申请的')
                .fontSize(12)
                .fontColor(Theme.textSecondary)
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .backgroundColor(Theme.surface)
                .borderRadius(16)
                .onClick(() => AppRouter.push('pages/MyAdoptions', { mode: 'MINE' } as MyAdoptionsParams, this))
              Text('收到的申请')
                .fontSize(12)
                .fontColor(Theme.textSecondary)
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .backgroundColor(Theme.surface)
                .borderRadius(16)
                .onClick(() => AppRouter.push('pages/MyAdoptions', { mode: 'OWNED' } as MyAdoptionsParams, this))
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        }
        .padding({ left: 16, right: 16, bottom: 14 })
        .width('100%')
      }

      Scroll() {
        Column({ space: 14 }) {
          if (!AppStatus.isBackendOnline()) {
            OfflineBanner({ text: '当前无法连接服务，领养信息可能无法及时更新', action: () => this.reload() })
          }

          if (this.errorText) {
            Text(this.errorText)
              .fontSize(13)
              .fontColor(Theme.danger)
              .width('100%')
          }

          SectionHeader({
            title: this.filter === 'MINE' ? '我的领养宠物' : '领养列表',
            actionText: this.filter === 'MINE' ? '发布' : '',
            onAction: () => AppRouter.push('pages/NewPet', { mode: 'ADOPT' } as NewPetParams, this)
          })

          if (!this.loading && this.visiblePets().length === 0) {
            EmptyState({
              title: this.filter === 'MINE' ? '你还没有发布领养信息' : '暂无匹配的领养宠物',
              description: this.filter === 'MINE' ? '点击右下方入口，发布待领养宠物。' : '换个关键词试试，或者稍后再来看看。',
              actionText: this.filter === 'MINE' ? '去发布' : '查看我的申请',
              action: () => this.filter === 'MINE'
                ? AppRouter.push('pages/NewPet', { mode: 'ADOPT' } as NewPetParams, this)
                : AppRouter.push('pages/MyAdoptions', { mode: 'MINE' } as MyAdoptionsParams, this)
            })
          } else {
            ForEach(this.visiblePets(), (pet: Pet) => {
              PetCard({
                pet: pet,
                summary: pet.description ?? '暂无描述',
                actionText: '查看详情',
                onTap: () => this.openDetail(pet)
              })
            }, (pet: Pet) => String(pet.id))

            if (this.loading) {
              Row({ space: 8 }) {
                LoadingProgress().width(20).height(20).color(Theme.primary)
                Text('正在加载领养宠物…').fontSize(12).fontColor(Theme.textMuted)
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding(16)
            }
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

  @Builder private FilterChip(label: string, value: AdoptFilter) {
    Text(label)
      .fontSize(12)
      .fontColor(this.filter === value ? Color.White : Theme.textSecondary)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(this.filter === value ? Theme.primary : Theme.surface)
      .borderRadius(16)
      .onClick(() => {
        this.filter = value;
        this.reload();
      })
  }
}
