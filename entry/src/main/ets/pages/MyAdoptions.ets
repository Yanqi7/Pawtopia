import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { AdoptionRequest, Pet } from '../model/Models';
import { ErrorText, SectionTitle } from '../components/Ui';
import { SessionStore } from '../store/SessionStore';
import { MediaAssets } from '../assets/MediaAssets';
import { Theme } from '../common/Theme';

interface AdoptionLine {
  request: AdoptionRequest;
  pet?: Pet;
}

@Entry
@Component
struct MyAdoptions {
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private lines: AdoptionLine[] = [];

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      AppRouter.replace('pages/Login');
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      const requests = await Api.getMyAdoptionRequests();
      const pets = await Promise.all(requests.map((request: AdoptionRequest) => Api.getPet(request.petId).catch(() => undefined)));
      this.lines = requests.map((request: AdoptionRequest, index: number) => {
        const line: AdoptionLine = { request: request, pet: pets[index] };
        return line;
      });
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
        Text('返回').fontSize(14).fontColor(Theme.primary).onClick(() => AppRouter.back())
      }
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      if (this.errorText) {
        ErrorText({ text: this.errorText })
      }

      Scroll() {
        Column({ space: 12 }) {
          SectionTitle({ title: `记录（${this.lines.length}）` })

          ForEach(this.lines, (line: AdoptionLine) => {
            Row({ space: 12 }) {
              Image(MediaAssets.petImage(line.pet?.image, line.pet?.id ?? line.request.petId, line.pet?.species))
                .width(88)
                .height(88)
                .borderRadius(20)
                .objectFit(ImageFit.Cover)

              Column({ space: 8 }) {
                Row() {
                  Text(line.pet?.name ?? `宠物 #${line.request.petId}`).fontSize(16).fontWeight(FontWeight.Medium)
                  Blank()
                  Text(line.request.status).fontSize(12).fontColor(line.request.status === 'PENDING' ? '#B26A00' : '#666')
                }
                Text(`${line.pet?.species ?? '宠物'} · ${line.pet?.breed ?? '等待资料补充'}`).fontSize(12).fontColor('#666')
                if (line.request.message) {
                  Text(line.request.message!).fontSize(13).fontColor('#333').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                Text(`联系人：${line.request.contactName ?? '-'} · ${line.request.contactPhone ?? '-'}`).fontSize(12).fontColor('#999')
                if (line.request.status === 'PENDING' && line.request.id) {
                  Button('撤回申请')
                    .height(32)
                    .padding({ left: 14, right: 14 })
                    .backgroundColor('#F3F6FB')
                    .fontColor('#FF5A5F')
                    .borderRadius(16)
                    .fontSize(12)
                    .onClick(() => this.cancel(line.request.id!))
                }
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(24)
          }, (line: AdoptionLine) => String(line.request.id))

          if (!this.loading && this.lines.length === 0) {
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
    .backgroundColor(Theme.background)
  }
}
