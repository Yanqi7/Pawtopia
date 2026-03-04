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
    Column() {
      Row() {
        Text('领养')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Blank()
        Button('发布')
          .height(32)
          .borderRadius(16)
          .backgroundColor('#2B7FFF')
          .fontColor(Color.White)
          .onClick(() => router.pushUrl({ url: 'pages/NewPet', params: { mode: 'ADOPT' } }))
      }
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      if (!AppStatus.isBackendOnline()) {
        OfflineBanner({ action: () => router.pushUrl({ url: 'pages/Login' }) })
          .padding({ left: 16, right: 16, bottom: 10 })
      }

      Row({ space: 10 }) {
        Button('领养广场')
          .height(32)
          .borderRadius(16)
          .backgroundColor(this.filter === 'ALL' ? '#2B7FFF' : '#F0F2F5')
          .fontColor(this.filter === 'ALL' ? Color.White : '#333')
          .onClick(() => {
            this.filter = 'ALL';
            this.reload();
          })
        Button('我发布的')
          .height(32)
          .borderRadius(16)
          .backgroundColor(this.filter === 'MINE' ? '#2B7FFF' : '#F0F2F5')
          .fontColor(this.filter === 'MINE' ? Color.White : '#333')
          .onClick(() => {
            this.filter = 'MINE';
            this.reload();
          })
        Blank()
        Button(this.loading ? '刷新中…' : '刷新')
          .height(32)
          .borderRadius(16)
          .backgroundColor('#F0F2F5')
          .onClick(() => this.reload())
      }
      .padding({ left: 16, right: 16, bottom: 10 })

      if (this.errorText) {
        Text(this.errorText).fontSize(13).fontColor(Color.Red).padding({ left: 16, right: 16, bottom: 8 })
      }

      List() {
        ForEach(this.pets, (pet: Pet) => {
          ListItem() {
            Column({ space: 6 }) {
              Row() {
                Text(`${pet.name}（${pet.species}）`).fontSize(16).fontWeight(FontWeight.Medium)
                Blank()
                Text(pet.adoptionCity ?? '-')
                  .fontSize(12)
                  .fontColor('#2B7FFF')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#EAF2FF')
                  .borderRadius(10)
              }
              Text(pet.description ?? '暂无描述').fontSize(13).fontColor('#666').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(`年龄：${pet.age ?? '-'}  性别：${pet.gender ?? '-'}  品种：${pet.breed ?? '-'}`)
                .fontSize(12)
                .fontColor('#999')
              if (pet.adoptionNote) {
                Text(`领养要求：${pet.adoptionNote}`)
                  .fontSize(12)
                  .fontColor('#888')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .padding(12)
            .backgroundColor('#F6F7F9')
            .borderRadius(12)
          }
          .padding({ left: 16, right: 16, bottom: 10 })
          .onClick(() => {
            if (pet.id) {
              router.pushUrl({ url: 'pages/PetDetail', params: { id: pet.id } });
            }
          })
        }, (pet: Pet) => String(pet.id))

        if (!this.loading && this.pets.length === 0) {
          ListItem() {
            Text('暂无内容').fontSize(13).fontColor('#999').width('100%').textAlign(TextAlign.Center).padding(24)
          }
        }
      }
    }
    .height('100%')
    .width('100%')
  }
}
