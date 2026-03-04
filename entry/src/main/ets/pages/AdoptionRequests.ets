import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Api } from '../api/Api';
import { AdoptionRequest, AdoptionRequestStatus, Pet } from '../model/Models';
import { ErrorText, SectionTitle } from '../components/Ui';

interface Params {
  petId?: number;
}

@Entry
@Component
struct AdoptionRequests {
  @State private petId: number = 0;
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private pet?: Pet = undefined;
  @State private requests: AdoptionRequest[] = [];

  aboutToAppear(): void {
    const params = router.getParams() as Params;
    this.petId = Number(params?.petId ?? 0);
    this.load();
  }

  private async load(): Promise<void> {
    if (!this.petId) {
      this.errorText = '无效宠物';
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      this.pet = await Api.getPet(this.petId);
      this.requests = await Api.getAdoptionRequestsByPet(this.petId);
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private async setStatus(id: number, status: AdoptionRequestStatus): Promise<void> {
    try {
      await Api.updateAdoptionRequestStatus(id, status);
      promptAction.showToast({ message: '已更新' });
      await this.load();
    } catch (e) {
      this.errorText = (e as Error).message || '更新失败';
    }
  }

  build() {
    Column() {
      Row() {
        Text('领养申请').fontSize(18).fontWeight(FontWeight.Bold)
        Blank()
        Text('返回').fontSize(14).fontColor('#2B7FFF').onClick(() => router.back())
      }
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      if (this.errorText) {
        ErrorText({ text: this.errorText })
      }

      Scroll() {
        Column({ space: 12 }) {
          if (this.pet) {
            Column({ space: 6 }) {
              Text(`${this.pet!.name}（${this.pet!.species}）`).fontSize(16).fontWeight(FontWeight.Medium)
              Text(`状态：${this.pet!.adoptionStatus ?? 'AVAILABLE'}  城市：${this.pet!.adoptionCity ?? '-'}`)
                .fontSize(12)
                .fontColor('#666')
            }
            .padding(12)
            .backgroundColor('#F6F7F9')
            .borderRadius(12)
          }

          SectionTitle({ title: `申请列表（${this.requests.length}）` })

          ForEach(this.requests, (r: AdoptionRequest) => {
            Column({ space: 8 }) {
              Row() {
                Text(`申请 #${r.id ?? '-'}`).fontSize(14).fontWeight(FontWeight.Medium)
                Blank()
                Text(r.status).fontSize(12).fontColor(r.status === 'PENDING' ? '#B26A00' : '#666')
              }
              if (r.message) {
                Text(r.message!).fontSize(13).fontColor('#333')
              }
              Text(`联系人：${r.contactName ?? '-'}  电话：${r.contactPhone ?? '-'}`)
                .fontSize(12)
                .fontColor('#999')

              if (r.status === 'PENDING') {
                Row({ space: 10 }) {
                  Button('拒绝')
                    .height(32)
                    .borderRadius(16)
                    .backgroundColor('#F0F2F5')
                    .onClick(() => {
                      if (r.id) {
                        this.setStatus(r.id, 'REJECTED');
                      }
                    })
                  Button('同意')
                    .height(32)
                    .borderRadius(16)
                    .backgroundColor('#2B7FFF')
                    .fontColor(Color.White)
                    .onClick(() => {
                      if (r.id) {
                        this.setStatus(r.id, 'APPROVED');
                      }
                    })
                }
              }
            }
            .padding(12)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .border({ width: 1, color: '#EEE' })
          }, (r: AdoptionRequest) => String(r.id))

          if (!this.loading && this.requests.length === 0) {
            Text('暂无申请').fontSize(13).fontColor('#999').width('100%').textAlign(TextAlign.Center).padding(24)
          }
        }
        .padding({ left: 16, right: 16, bottom: 24 })
        .width('100%')
      }
      .height('100%')
    }
    .height('100%')
    .width('100%')
  }
}

