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
    Column() {
      Row() {
        Text('医疗')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Blank()
        Button('添加宠物')
          .height(32)
          .borderRadius(16)
          .backgroundColor('#2B7FFF')
          .fontColor(Color.White)
          .onClick(() => router.pushUrl({ url: 'pages/NewPet', params: { mode: 'MEDICAL' } }))
      }
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      if (!AppStatus.isBackendOnline()) {
        OfflineBanner({ action: () => router.pushUrl({ url: 'pages/Login' }) })
          .padding({ left: 16, right: 16, bottom: 10 })
      }

      Row({ space: 10 }) {
        Button(this.loading ? '刷新中…' : '刷新')
          .height(32)
          .borderRadius(16)
          .backgroundColor('#F0F2F5')
          .onClick(() => this.reload())
        Blank()
      }.padding({ left: 16, right: 16, bottom: 10 })

      if (this.errorText) {
        Text(this.errorText).fontSize(13).fontColor(Color.Red).padding({ left: 16, right: 16, bottom: 8 })
      }

      List() {
        ForEach(this.pets, (pet: Pet) => {
          ListItem() {
            Column({ space: 6 }) {
              Text(`${pet.name}（${pet.species}）`).fontSize(16).fontWeight(FontWeight.Medium)
              Text(`年龄：${pet.age ?? '-'}  性别：${pet.gender ?? '-'}  品种：${pet.breed ?? '-'}`)
                .fontSize(12)
                .fontColor('#999')
              Row({ space: 10 }) {
                Button('健康档案')
                  .height(32)
                  .borderRadius(16)
                  .backgroundColor('#2B7FFF')
                  .fontColor(Color.White)
                  .onClick(() => {
                    if (pet.id) {
                      router.pushUrl({ url: 'pages/HealthRecords', params: { petId: pet.id } });
                    }
                  })
                Button('详情')
                  .height(32)
                  .borderRadius(16)
                  .backgroundColor('#F0F2F5')
                  .onClick(() => {
                    if (pet.id) {
                      router.pushUrl({ url: 'pages/PetDetail', params: { id: pet.id } });
                    }
                  })
              }
            }
            .padding(12)
            .backgroundColor('#F6F7F9')
            .borderRadius(12)
          }
          .padding({ left: 16, right: 16, bottom: 10 })
        }, (pet: Pet) => String(pet.id))

        if (!this.loading && this.pets.length === 0) {
          ListItem() {
            Text('请先添加宠物').fontSize(13).fontColor('#999').width('100%').textAlign(TextAlign.Center).padding(24)
          }
        }
      }
    }
    .height('100%')
    .width('100%')
  }
}
