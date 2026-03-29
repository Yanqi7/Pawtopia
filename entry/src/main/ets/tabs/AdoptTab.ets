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
        // Header with search
        Row({ space: 8 }) {
          TextInput({ placeholder: '搜索领养宠物/地点' })
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

        // Filter buttons
        Row({ space: 8 }) {
          Button(this.filter === 'ALL' ? '全部' : '全部')
            .height(32)
            .fontSize(13)
            .type(ButtonType.Normal)
            .backgroundColor(this.filter === 'ALL' ? $r('sys.color.ohos_id_color_brand') : $r('sys.color.ohos_id_color_button_normal'))
            .fontColor(this.filter === 'ALL' ? Color.White : $r('sys.color.ohos_id_color_text_primary'))
            .borderRadius(16)
            .onClick(() => { this.filter = 'ALL'; this.reload(); })

          Button(this.filter === 'MINE' ? '我发布的' : '我发布的')
            .height(32)
            .fontSize(13)
            .type(ButtonType.Normal)
            .backgroundColor(this.filter === 'MINE' ? $r('sys.color.ohos_id_color_brand') : $r('sys.color.ohos_id_color_button_normal'))
            .fontColor(this.filter === 'MINE' ? Color.White : $r('sys.color.ohos_id_color_text_primary'))
            .borderRadius(16)
            .onClick(() => { this.filter = 'MINE'; this.reload(); })

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

        // Grid layout for pets
        Grid() {
          ForEach(this.pets, (pet: Pet) => {
            GridItem() {
              Column({ space: 6 }) {
                if (pet.adoptionStatus !== 'ADOPTED') {
                  Image($r('app.media.dog'))
                    .width('100%')
                    .height(100)
                    .borderRadius(8)
                    .objectFit(ImageFit.Cover)
                } else {
                  Image($r('app.media.dog'))
                    .width('100%')
                    .height(100)
                    .borderRadius(8)
                    .objectFit(ImageFit.Cover)
                    .opacity(0.5)
                }
                Text(pet.name ?? '宠物名称')
                  .fontSize(13)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`暂住地: ${pet.adoptionCity ?? '暂无'}`)
                  .fontSize(11)
                  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Row() {
                  Text('状态: 良好')
                    .fontSize(11)
                    .fontColor($r('sys.color.ohos_id_color_brand'))
                    .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
                    .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                    .borderRadius(4)
                  if (pet.age) {
                    Text(`${pet.age}月`)
                      .fontSize(11)
                      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
                  }
                }
              }
              .padding(8)
              .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
              .borderRadius(8)
            }
          }, (pet: Pet) => String(pet.id))
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(12)
        .columnsGap(12)
        .padding({ left: 12, right: 12 })
        .layoutWeight(1)
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
