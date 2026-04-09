import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Pet } from '../model/Models';
import { SessionStore } from '../store/SessionStore';
import { AppStatus } from '../app/AppStatus';
import { EmptyState, OfflineBanner } from '../components/Ui';
import { MediaAssets } from '../assets/MediaAssets';
import { adoptionStatusLabel, petGenderLabel } from '../common/Formatters';
import { Theme } from '../common/Theme';

type AdoptFilter = 'ALL' | 'MINE';

interface NewPetParams {
  mode?: string;
}

interface PetDetailParams {
  id?: number;
}

@Component
export struct AdoptTab {
  @State private filter: AdoptFilter = 'ALL';
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private pets: Pet[] = [];

  aboutToAppear(): void {
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
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private openDetail(pet?: Pet): void {
    if (!pet?.id) {
      return;
    }
    AppRouter.push('pages/PetDetail', { id: pet.id } as PetDetailParams);
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Row({ space: 10 }) {
          Column({ space: 4 }) {
            Text('宠物领养')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.textPrimary)
            Text('点击宠物卡片查看大图、基本信息、主人寄语和申请入口')
              .fontSize(12)
              .fontColor(Theme.textSecondary)
          }
          .layoutWeight(1)
          Button(this.filter === 'ALL' ? '查看我发布的' : '查看全部')
            .height(34)
            .backgroundColor('#E8F1FF')
            .fontColor(Theme.primary)
            .borderRadius(17)
            .fontSize(12)
            .onClick(() => {
              this.filter = this.filter === 'ALL' ? 'MINE' : 'ALL';
              this.reload();
            })
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })
        .width('100%')

        if (!AppStatus.isBackendOnline()) {
          OfflineBanner({ text: '当前为本地缓存数据，依然可以查看宠物卡片详情', action: () => this.reload() })
            .padding({ left: 16, right: 16, bottom: 8 })
        }

        if (this.errorText) {
          Text(this.errorText)
            .fontSize(13)
            .fontColor(Color.Red)
            .padding({ left: 16, right: 16, bottom: 8 })
        }

        if (!this.loading && this.pets.length === 0) {
          EmptyState({
            title: this.filter === 'MINE' ? '你还没有发布领养信息' : '暂无可展示的领养宠物',
            description: this.filter === 'MINE' ? '点击右下角按钮，发布待领养宠物。' : '稍后再来看看，或者切换到“我发布的”。',
            actionText: this.filter === 'MINE' ? '去发布' : '刷新',
            action: () => this.filter === 'MINE' ? AppRouter.push('pages/NewPet', { mode: 'ADOPT' } as NewPetParams) : this.reload()
          })
        } else {
          List({ space: 14 }) {
            ForEach(this.pets, (pet: Pet) => {
              ListItem() {
                Column({ space: 12 }) {
                  Stack({ alignContent: Alignment.BottomStart }) {
                    Image(MediaAssets.petImage(pet.image, pet.id ?? 0, pet.species))
                      .width('100%')
                      .height(220)
                      .borderRadius(24)
                      .objectFit(ImageFit.Cover)
                    Column({ space: 8 }) {
                      Row({ space: 8 }) {
                        Text(pet.name)
                          .fontSize(22)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(Color.White)
                          .layoutWeight(1)
                        Text(adoptionStatusLabel(pet.adoptionStatus))
                          .fontSize(11)
                          .fontColor('#2B7FFF')
                          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                          .backgroundColor('#FFFFFFEE')
                          .borderRadius(12)
                      }
                      Text(`${pet.species} · ${pet.breed ?? '品种待补充'} · ${petGenderLabel(pet.gender)} · ${pet.age ?? '-'} 岁`)
                        .fontSize(12)
                        .fontColor('#F8FAFC')
                    }
                    .width('100%')
                    .padding(16)
                    .linearGradient({ angle: 180, colors: [['#11182700', 0], ['#111827B3', 1]] })
                    .borderRadius(24)
                  }

                  Column({ space: 10 }) {
                    Text(pet.description ?? '暂无描述')
                      .fontSize(13)
                      .lineHeight(20)
                      .fontColor(Theme.textPrimary)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Row({ space: 8 }) {
                      Text(pet.adoptionCity ? `所在城市：${pet.adoptionCity}` : '支持同城优先')
                        .fontSize(12)
                        .fontColor(Theme.textSecondary)
                        .layoutWeight(1)
                      if (pet.adoptionNote) {
                        Text('含主人寄语')
                          .fontSize(11)
                          .fontColor('#FF8A3D')
                          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                          .backgroundColor('#FFF3E0')
                          .borderRadius(10)
                      }
                    }

                    Row() {
                      Text('点击卡片查看宠物信息、主人寄语与申请入口')
                        .fontSize(12)
                        .fontColor(Theme.primary)
                      Blank()
                      Text('查看详情 ›')
                        .fontSize(12)
                        .fontColor(Theme.primary)
                        .fontWeight(FontWeight.Medium)
                    }
                    .width('100%')
                  }
                  .padding({ left: 2, right: 2 })
                }
                .padding(14)
                .backgroundColor(Color.White)
                .borderRadius(28)
              }
              .padding({ left: 16, right: 16, bottom: 14 })
              .onClick(() => this.openDetail(pet))
            }, (pet: Pet) => String(pet.id))

            ListItem() {
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
          .layoutWeight(1)
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .height('100%')
      .width('100%')
      .backgroundColor(Theme.background)

      Button('+')
        .width(56)
        .height(56)
        .margin({ right: 18, bottom: 18 })
        .borderRadius(28)
        .backgroundColor(Theme.primary)
        .fontColor(Color.White)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .onClick(() => AppRouter.push('pages/NewPet', { mode: 'ADOPT' } as NewPetParams))
    }
    .height('100%')
    .width('100%')
  }
}
