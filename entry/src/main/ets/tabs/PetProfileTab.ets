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
        // 浅粉红顶部区域
        Column({ space: 8 }) {
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
              TextInput({ placeholder: '搜索宠物档案' })
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
              .fillColor('#666')
          }
          .padding({ left: 16, right: 16 })
        }
        .width('100%')
        .backgroundColor('#F5E6F0')
        .padding({ top: 12, bottom: 8 })

        if (!AppStatus.isBackendOnline()) {
          OfflineBanner({ action: () => router.pushUrl({ url: 'pages/Login' }) })
            .padding({ left: 16, right: 16, bottom: 10 })
        }

        if (this.errorText) {
          Text(this.errorText)
            .fontSize(13)
            .fontColor('#ff4d4f')
            .padding(16)
        }

        // Grid layout
        Grid() {
          ForEach(this.pets, (pet: Pet) => {
            GridItem() {
              Column({ space: 6 }) {
                Stack() {
                  Image(pet.image ? $r(`app.media.${pet.image}`) : $r('app.media.dog'))
                    .width('100%')
                    .height(100)
                    .borderRadius(8)
                    .objectFit(ImageFit.Cover)
                  Row() {
                    Blank()
                    Image($r('app.media.work'))
                      .width(24)
                      .height(24)
                      .fillColor('#FF69B4')
                      .padding(6)
                  }
                  .width('100%')
                }

                Text(pet.name ?? '宠物名称')
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`年龄: ${pet.age ?? '-'}岁`)
                  .fontSize(11)
                  .fontColor('#666666')
                Text('病史: 无')
                  .fontSize(11)
                  .fontColor('#666666')
              }
              .padding(8)
              .backgroundColor('#FFF0F6')
              .borderRadius(8)
              .border({ width: 1, color: '#FFD4E5' })
            }
          }, (pet: Pet) => String(pet.id))
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(12)
        .columnsGap(12)
        .padding({ left: 12, right: 12 })
        .layoutWeight(1)
      }
      .height('100%')
      .width('100%')
      .backgroundColor('#F9F0F6')

      // FAB button
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
              .onClick(() => router.pushUrl({ url: 'pages/NewPet', params: { mode: 'MEDICAL' } }))
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
