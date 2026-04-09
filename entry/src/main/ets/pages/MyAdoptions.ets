import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { AdoptionRequest, Pet } from '../model/Models';
import { EmptyState, ErrorText, OfflineBanner, SectionTitle } from '../components/Ui';
import { SessionStore } from '../store/SessionStore';
import { MediaAssets } from '../assets/MediaAssets';
import { Theme } from '../common/Theme';
import { adoptionRequestStatusLabel, relativeTime } from '../common/Formatters';

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
        const line: AdoptionLine = {
          request: request,
          pet: pets[index]
        };
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
        Text('我的领养申请')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('返回')
          .fontSize(14)
          .fontColor(Theme.primary)
          .onClick(() => AppRouter.back())
      }
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      if (this.errorText) {
        ErrorText({ text: this.errorText })
      }

      if (!this.loading && this.lines.length === 0) {
        EmptyState({
          title: '你还没有领养申请',
          description: '去领养页看看合适的毛孩子，提交申请后会在这里跟进状态。',
          actionText: '去领养页',
          action: () => AppRouter.replace('pages/MainTabs')
        })
      } else {
        Scroll() {
          Column({ space: 14 }) {
            SectionTitle({ title: `申请记录（${this.lines.length}）` })

            ForEach(this.lines, (line: AdoptionLine) => {
              Column({ space: 12 }) {
                Stack({ alignContent: Alignment.BottomStart }) {
                  Image(MediaAssets.petImage(line.pet?.image, line.pet?.id ?? line.request.petId, line.pet?.species))
                    .width('100%')
                    .height(190)
                    .borderRadius(24)
                    .objectFit(ImageFit.Cover)
                  Column({ space: 6 }) {
                    Row({ space: 8 }) {
                      Text(line.pet?.name ?? `宠物 #${line.request.petId}`)
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(Color.White)
                        .layoutWeight(1)
                      Text(adoptionRequestStatusLabel(line.request.status))
                        .fontSize(11)
                        .fontColor(Theme.primary)
                        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                        .backgroundColor('#FFFFFFEE')
                        .borderRadius(12)
                    }
                    Text(`${line.pet?.species ?? '宠物'} · ${line.pet?.breed ?? '待补充'} · 提交于 ${relativeTime(line.request.createdAt)}`)
                      .fontSize(12)
                      .fontColor('#F8FAFC')
                  }
                  .width('100%')
                  .padding(16)
                  .linearGradient({ angle: 180, colors: [['#11182700', 0], ['#111827B8', 1]] })
                  .borderRadius(24)
                }

                Column({ space: 8 }) {
                  if (line.request.message) {
                    Text(line.request.message)
                      .fontSize(13)
                      .fontColor(Theme.textPrimary)
                      .lineHeight(20)
                  }
                  Row() {
                    Text(`联系人：${line.request.contactName ?? '-'} · ${line.request.contactPhone ?? '-'}`)
                      .fontSize(12)
                      .fontColor(Theme.textSecondary)
                    Blank()
                    if (line.request.status === 'PENDING' && line.request.id) {
                      Button('撤回申请')
                        .height(32)
                        .padding({ left: 14, right: 14 })
                        .backgroundColor('#FFF1F0')
                        .fontColor('#D14343')
                        .borderRadius(16)
                        .fontSize(12)
                        .onClick(() => this.cancel(line.request.id!))
                    }
                  }
                }
                .padding({ left: 2, right: 2, bottom: 2 })
              }
              .padding(14)
              .backgroundColor(Color.White)
              .borderRadius(28)
            }, (line: AdoptionLine) => String(line.request.id))

            if (this.loading) {
              Row({ space: 8 }) {
                LoadingProgress().width(20).height(20).color(Theme.primary)
                Text('正在同步申请状态…').fontSize(12).fontColor(Theme.textMuted)
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding(12)
            }
          }
          .padding({ left: 16, right: 16, bottom: 24 })
          .width('100%')
        }
        .layoutWeight(1)
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }
}
