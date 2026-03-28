import router from '@ohos.router';
import { Api } from '../api/Api';
import { Pet } from '../model/Models';
import { SessionStore } from '../store/SessionStore';
import { AppStatus } from '../app/AppStatus';
import { OfflineBanner } from '../components/Ui';

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
      return;
    }
    const userId = user.id;
    this.loading = true;
    this.errorText = '';
    try {
      this.pets = await Api.getMyPets(userId);
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  build() {
    Stack() {
      Column() {
        // Pink header with search
        Column({ space: 10 }) {
          Row({ space: 10 }) {
            Image($r('app.media.people')).width(40).height(40).borderRadius(20)
            TextInput({ placeholder: '搜索宠物档案' })
              .layoutWeight(1)
              .height(36)
              .backgroundColor('rgba(255,255,255,0.3)')
              .borderRadius(18)
              .padding({ left: 12, right: 12 })
            Image($r('app.media.more')).width(24).height(24)
          }
          .padding({ left: 16, right: 16, bottom: 8 })
        }
        .width('100%')
        .linearGradient({
          angle: 135,
          colors: [['#FFD9E8', 0.0], ['#FFC9DA', 1.0]]
        })
        .padding({ top: 12 })

        if (!AppStatus.isBackendOnline()) {
          OfflineBanner({ action: () => router.pushUrl({ url: 'pages/Login' }) })
            .padding({ left: 16, right: 16, bottom: 10 })
        }

        if (this.errorText) {
          Text(this.errorText).fontSize(13).fontColor(Color.Red).padding(16)
        }

        // Grid layout
        Grid() {
          ForEach(this.pets, (pet: Pet) => {
            GridItem() {
              Column({ space: 6 }) {
                Stack() {
                  Image($r('app.media.dog')).width('100%').height(120).borderRadius(8).objectFit(ImageFit.Cover)
                  Row() {
                    Blank()
                    Image($r('app.media.work')).width(24).height(24).padding(6)
                  }
                  .width('100%')
                }

                Text(pet.name ?? '宠物名称').fontSize(12).fontWeight(FontWeight.Medium).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`年龄: ${pet.age ?? '-'}`).fontSize(11).fontColor('#666')
                Text(`病史: 无`).fontSize(11).fontColor('#666')
              }
              .padding(8)
              .backgroundColor('#F9E8F0')
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

      // FAB button
      Column() {
        Blank()
        Row() {
          Blank()
          Button()
            .width(56)
            .height(56)
            .borderRadius(28)
            .backgroundColor('#2B7FFF')
            .onClick(() => router.pushUrl({ url: 'pages/NewPet', params: { mode: 'MEDICAL' } }))
            .overlay(Text('+').fontSize(28).fontColor(Color.White).fontWeight(FontWeight.Bold), Alignment.Center)
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
