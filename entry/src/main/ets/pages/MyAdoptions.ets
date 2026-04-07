import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { AdoptionRequest } from '../model/Models';
import { ErrorText, SectionTitle } from '../components/Ui';
import { SessionStore } from '../store/SessionStore';

@Entry
@Component
struct MyAdoptions {
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private requests: AdoptionRequest[] = [];

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    const u = SessionStore.getUser();
    if (!u || !u.id) {
      AppRouter.replace('pages/Login');
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      const c = await Api.client();
      this.requests = await c.get<AdoptionRequest[]>('/api/adoptions/requests/mine');
      this.requests = [...this.requests].sort((a, b) => (b.id ?? 0) - (a.id ?? 0));
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private async cancel(id: number): Promise<void> {
    try {
      await Api.cancelAdoptionRequest(id);
      await this.load();
    } catch (e) {
      this.errorText = (e as Error).message || '撤回失败';
    }
  }

  build() {
    Column() {
      Row() {
        Text('我的领养申请').fontSize(18).fontWeight(FontWeight.Bold)
        Blank()
        Text('返回').fontSize(14).fontColor('#2B7FFF').onClick(() => AppRouter.back())
      }
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      if (this.errorText) {
        ErrorText({ text: this.errorText })
      }

      Scroll() {
        Column({ space: 12 }) {
          SectionTitle({ title: `记录（${this.requests.length}）` })

          ForEach(this.requests, (r: AdoptionRequest) => {
            Column({ space: 8 }) {
              Row() {
                Text(`宠物 #${r.petId}`).fontSize(14).fontWeight(FontWeight.Medium)
                Blank()
                Text(r.status).fontSize(12).fontColor(r.status === 'PENDING' ? '#B26A00' : '#666')
              }
              if (r.message) {
                Text(r.message!).fontSize(13).fontColor('#333').maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              Text(`联系人：${r.contactName ?? '-'}  电话：${r.contactPhone ?? '-'}`)
                .fontSize(12)
                .fontColor('#999')

              if (r.status === 'PENDING') {
                Row({ space: 10 }) {
                  Button('撤回申请')
                    .height(32)
                    .borderRadius(16)
                    .backgroundColor('#F0F2F5')
                    .onClick(() => {
                      if (r.id) {
                        this.cancel(r.id);
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
            Text('暂无申请记录').fontSize(13).fontColor('#999').width('100%').textAlign(TextAlign.Center).padding(24)
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
