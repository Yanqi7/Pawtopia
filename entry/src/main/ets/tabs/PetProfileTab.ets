import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Pet } from '../model/Models';
import { SessionStore } from '../store/SessionStore';
import { AppStatus } from '../app/AppStatus';
import { EmptyState, OfflineBanner } from '../components/Ui';
import { Theme } from '../common/Theme';
import { MediaAssets } from '../assets/MediaAssets';
import { petGenderLabel, shortDate } from '../common/Formatters';

interface NewPetParams {
  mode?: string;
}

interface PetDetailParams {
  id?: number;
}

interface PetRouteParams {
  petId?: number;
}

@Component
export struct PetProfileTab {
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private pets: Pet[] = [];

  aboutToAppear(): void {
    if (this.pets.length === 0) {
      this.reload();
    }
  }

  private async reload(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      this.pets = [];
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      this.pets = await Api.getMyPets(user.id);
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Stack({ alignContent: Alignment.BottomStart }) {
          Image(MediaAssets.profileHero())
            .width('100%')
            .height(178)
            .objectFit(ImageFit.Cover)
          Column()
            .width('100%')
            .height(178)
            .linearGradient({ angle: 180, colors: [['#0F172A08', 0], ['#0F172A48', 0.45], ['#F6F7F8', 1]] })
          Column({ space: 6 }) {
            Text('宠物档案')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text('点击标签卡可快速查看生理情况、详细资料和健康档案')
              .fontSize(11)
              .fontColor('#F8FAFC')
          }
          .padding({ left: 16, right: 16, bottom: 12 })
          .width('100%')
        }

        if (!AppStatus.isBackendOnline()) {
          OfflineBanner({ text: '当前使用本地缓存档案数据，仍可继续查看详情。', action: () => this.reload() })
            .padding({ left: 16, right: 16, top: 10 })
        }

        if (this.errorText) {
          Text(this.errorText)
            .fontSize(13)
            .fontColor('#D14343')
            .padding({ left: 16, right: 16, top: 10 })
        }

        if (!this.loading && this.pets.length === 0) {
          EmptyState({
            title: '还没有宠物档案',
            description: '先添加一只宠物，后续可以维护详细资料与健康档案。',
            actionText: '添加宠物',
            action: () => AppRouter.push('pages/NewPet', { mode: 'MEDICAL' } as NewPetParams)
          })
        } else {
          List({ space: 14 }) {
            ForEach(this.pets, (pet: Pet) => {
              ListItem() {
                Column({ space: 14 }) {
                  Row({ space: 12 }) {
                    Image(MediaAssets.petImage(pet.image, pet.id ?? 0, pet.species))
                      .width(108)
                      .height(108)
                      .borderRadius(20)
                      .objectFit(ImageFit.Cover)
                    Column({ space: 8 }) {
                      Text(pet.name)
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#18191C')
                      Text(`${pet.species} · ${pet.breed ?? '品种待补充'} · ${petGenderLabel(pet.gender)} · ${pet.age ?? '-'} 岁`)
                        .fontSize(12)
                        .fontColor('#61666D')
                      Text(pet.description ?? '暂无描述')
                        .fontSize(12)
                        .fontColor('#18191C')
                        .lineHeight(18)
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(`最近更新：${shortDate(pet.updatedAt ?? pet.createdAt)}`)
                        .fontSize(11)
                        .fontColor('#9499A0')
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                  }

                  Row({ space: 10 }) {
                    Button('生理情况')
                      .layoutWeight(1)
                      .height(34)
                      .backgroundColor('#F6F7F8')
                      .fontColor(Theme.primary)
                      .borderRadius(17)
                      .fontSize(12)
                      .onClick(() => AppRouter.push('pages/PetDetail', { id: pet.id } as PetDetailParams))
                    Button('详细信息')
                      .layoutWeight(1)
                      .height(34)
                      .backgroundColor('#F6F7F8')
                      .fontColor('#18191C')
                      .borderRadius(17)
                      .fontSize(12)
                      .onClick(() => AppRouter.push('pages/PetDetail', { id: pet.id } as PetDetailParams))
                    Button('健康档案')
                      .layoutWeight(1)
                      .height(34)
                      .backgroundColor('#E8F1FF')
                      .fontColor(Theme.primary)
                      .borderRadius(17)
                      .fontSize(12)
                      .onClick(() => AppRouter.push('pages/HealthRecords', { petId: pet.id } as PetRouteParams))
                  }
                }
                .padding(16)
                .backgroundColor(Color.White)
                .borderRadius(24)
              }
              .padding({ left: 16, right: 16, bottom: 14 })
            }, (pet: Pet) => String(pet.id))

            ListItem() {
              if (this.loading) {
                Row({ space: 8 }) {
                  LoadingProgress().width(20).height(20).color(Theme.primary)
                  Text('正在同步宠物档案…').fontSize(12).fontColor(Theme.textMuted)
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .padding(16)
              }
            }
          }
          .layoutWeight(1)
        }
      }
      .height('100%')
      .width('100%')
      .backgroundColor('#F6F7F8')

      Button('+')
        .width(56)
        .height(56)
        .margin({ right: 18, bottom: 18 })
        .borderRadius(28)
        .backgroundColor(Theme.primary)
        .fontColor(Color.White)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .onClick(() => AppRouter.push('pages/NewPet', { mode: 'MEDICAL' } as NewPetParams))
    }
    .height('100%')
    .width('100%')
  }
}
