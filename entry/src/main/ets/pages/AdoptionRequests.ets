import { AppPrompt } from '../common/AppPrompt';
import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { AdoptionRequest, AdoptionRequestStatus, Pet } from '../model/Models';
import { EmptyState, ErrorText, SectionTitle } from '../components/Ui';
import { MediaAssets } from '../assets/MediaAssets';
import { Theme } from '../common/Theme';
import { adoptionRequestStatusLabel, relativeTime } from '../common/Formatters';

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
    const params = AppRouter.params<Params>();
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
      AppPrompt.toast('已更新申请状态');
      await this.load();
    } catch (e) {
      this.errorText = (e as Error).message || '更新失败';
    }
  }

  build() {
    Column() {
      Row() {
        Text('领养审批').fontSize(18).fontWeight(FontWeight.Bold)
        Blank()
        Text('返回').fontSize(14).fontColor(Theme.primary).onClick(() => AppRouter.back())
      }
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      if (this.errorText) {
        ErrorText({ text: this.errorText })
      }

      if (!this.loading && this.requests.length === 0 && !this.errorText) {
        EmptyState({
          title: '还没有收到申请',
          description: '继续等待合适的申请人留言，或者完善宠物介绍提高匹配度。',
          actionText: '返回详情',
          action: () => AppRouter.back()
        })
      } else {
        Scroll() {
          Column({ space: 14 }) {
            if (this.pet) {
              Stack({ alignContent: Alignment.BottomStart }) {
                Image(MediaAssets.petImage(this.pet.image, this.pet.id ?? 0, this.pet.species))
                  .width('100%')
                  .height(180)
                  .borderRadius(24)
                  .objectFit(ImageFit.Cover)
                Column({ space: 6 }) {
                  Text(`${this.pet.name} 的申请列表`)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                  Text(`${this.pet.species} · ${this.pet.breed ?? '待补充'} · ${this.pet.adoptionCity ?? '同城优先'}`)
                    .fontSize(12)
                    .fontColor('#F8FAFC')
                }
                .width('100%')
                .padding(16)
                .linearGradient({ angle: 180, colors: [['#11182700', 0], ['#111827B8', 1]] })
                .borderRadius(24)
              }
            }

            SectionTitle({ title: `申请列表（${this.requests.length}）` })
            ForEach(this.requests, (request: AdoptionRequest) => {
              Column({ space: 10 }) {
                Row() {
                  Text(request.contactName ?? `申请人 #${request.requesterId}`)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.textPrimary)
                  Blank()
                  Text(adoptionRequestStatusLabel(request.status))
                    .fontSize(11)
                    .fontColor(request.status === 'PENDING' ? '#B26A00' : Theme.primary)
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .backgroundColor(request.status === 'PENDING' ? '#FFF3E0' : '#E8F1FF')
                    .borderRadius(12)
                }
                Text(`联系电话：${request.contactPhone ?? '-'} · ${relativeTime(request.createdAt)}`)
                  .fontSize(12)
                  .fontColor(Theme.textSecondary)
                if (request.message) {
                  Text(request.message)
                    .fontSize(13)
                    .fontColor(Theme.textPrimary)
                    .lineHeight(20)
                }
                if (request.status === 'PENDING' && request.id) {
                  Row({ space: 10 }) {
                    Button('拒绝')
                      .height(34)
                      .padding({ left: 16, right: 16 })
                      .borderRadius(17)
                      .backgroundColor('#FFF1F0')
                      .fontColor('#D14343')
                      .onClick(() => this.setStatus(request.id!, 'REJECTED'))
                    Button('同意')
                      .height(34)
                      .padding({ left: 16, right: 16 })
                      .borderRadius(17)
                      .backgroundColor(Theme.primary)
                      .fontColor(Color.White)
                      .onClick(() => this.setStatus(request.id!, 'APPROVED'))
                  }
                }
              }
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(24)
            }, (request: AdoptionRequest) => String(request.id))

            if (this.loading) {
              Row({ space: 8 }) {
                LoadingProgress().width(20).height(20).color(Theme.primary)
                Text('正在同步申请列表…').fontSize(12).fontColor(Theme.textMuted)
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
