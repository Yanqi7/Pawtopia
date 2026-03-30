import router from '@ohos.router';
import { Api } from '../api/Api';
import { Pet } from '../model/Models';
import { SessionStore } from '../store/SessionStore';
import { AppStatus } from '../app/AppStatus';
import { OfflineBanner } from '../components/Ui';

type AdoptFilter = 'ALL' | 'MINE';

@Component
export struct AdoptTab {
  @State private filter: AdoptFilter = 'ALL';
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
    this.loading = true;
    this.errorText = '';
    try {
      const all = await Api.getAdoptionListings();
      if (user && user.id) {
        const userId = user.id;
        if (this.filter === 'MINE') {
          this.pets = all.filter((p) => p.ownerId === userId);
        } else {
          this.pets = all.filter((p) => p.ownerId !== userId);
        }
      } else {
        this.pets = all;
      }
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  build() {
    Stack() {
      Column() {
        // 蓝色顶部
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Image($r('app.media.people')).width(40).height(40).borderRadius(20)
            TextInput({ placeholder: '搜索领养宠物/地点' })
              .layoutWeight(1)
              .height(36)
              .padding({ left: 12, right: 12 })
              .borderRadius(18)
              .backgroundColor(Color.White)
            Image($r('app.media.more')).width(24).height(24).fillColor(Color.White)
          }
          .padding({ left: 16, right: 16 })

          Row({ space: 8 }) {
            Button('全部')
              .height(32)
              .backgroundColor(this.filter === 'ALL' ? Color.White : 'transparent')
              .fontColor(this.filter === 'ALL' ? '#2B7FFF' : Color.White)
              .onClick(() => { this.filter = 'ALL'; this.reload(); })
            Button('我发布的')
              .height(32)
              .backgroundColor(this.filter === 'MINE' ? Color.White : 'transparent')
              .fontColor(this.filter === 'MINE' ? '#2B7FFF' : Color.White)
              .onClick(() => { this.filter = 'MINE'; this.reload(); })
            Blank()
          }
          .padding({ left: 16, right: 16, bottom: 8 })
        }
        .width('100%')
        .linearGradient({
          angle: 135,
          colors: [['#3B9AFF', 0.0], ['#2B7FFF', 1.0]]
        })
        .padding({ top: 12 })

        if (!AppStatus.isBackendOnline()) {
          OfflineBanner({ action: () => router.pushUrl({ url: 'pages/Login' }) })
            .padding({ left: 16, right: 16, bottom: 10 })
        }

        if (this.errorText) {
          Text(this.errorText).fontSize(13).fontColor(Color.Red).padding(16)
        }

        // 3列网格
        Grid() {
          ForEach(this.pets, (pet: Pet) => {
            GridItem() {
              Column({ space: 6 }) {
                Image(pet.image ? $r(`app.media.${pet.image}`) : $r('app.media.dog'))
                  .width('100%')
                  .height(100)
                  .borderRadius(8)
                  .objectFit(ImageFit.Cover)
                Text(pet.name ?? '宠物名称')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`暂住地: ${pet.adoptionCity ?? '暂无'}`)
                  .fontSize(11)
                  .fontColor('#666')
                Row() {
                  Text('状态: 良好').fontSize(11).fontColor('#2B7FFF').backgroundColor('#EAF2FF').padding({ left: 4, right: 4, top: 2, bottom: 2 }).borderRadius(4)
                  if (pet.age) {
                    Text(`${pet.age}月`).fontSize(11).fontColor('#999')
                  }
                }
              }
              .padding(8)
              .backgroundColor('#F6F7F9')
              .borderRadius(8)
            }
          }, (pet: Pet) => String(pet.id))
        }
        .columnsTemplate('1fr 1fr 1fr')
        .padding({ left: 12, right: 12 })
        .layoutWeight(1)
      }
      .height('100%')
      .width('100%')

      // FAB
      Column() {
        Blank()
        Row() {
          Blank()
          Stack() {
            Button()
              .width(56)
              .height(56)
              .borderRadius(28)
              .backgroundColor('#2B7FFF')
              .onClick(() => router.pushUrl({ url: 'pages/NewPet', params: { mode: 'ADOPT' } }))
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
