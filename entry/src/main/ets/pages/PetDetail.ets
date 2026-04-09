import { AppPrompt } from '../common/AppPrompt';
import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Pet, PetMessage } from '../model/Models';
import { SessionStore } from '../store/SessionStore';
import { MediaAssets } from '../assets/MediaAssets';
import { adoptionStatusLabel, petGenderLabel, relativeTime } from '../common/Formatters';
import { Theme } from '../common/Theme';
import { MockData } from '../mock/MockData';

interface IdParams {
  id?: number;
}

interface PetRouteParams {
  petId?: number;
}

@Entry
@Component
struct PetDetail {
  @State private petId: number = 0;
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private pet: Pet | undefined = undefined;
  @State private adoptMessage: string = '';
  @State private adoptContactName: string = '';
  @State private adoptContactPhone: string = '';
  @State private adoptSubmitting: boolean = false;
  @State private messages: PetMessage[] = [];

  aboutToAppear(): void {
    const params = AppRouter.params<IdParams>();
    this.petId = Number(params?.id ?? 0);
    const user = SessionStore.getUser();
    this.adoptContactName = user?.nickname ?? '';
    this.adoptContactPhone = user?.phone ?? '';
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
      this.messages = MockData.petMessagesByPet(this.petId);
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
      this.messages = MockData.petMessagesByPet(this.petId);
    } finally {
      this.loading = false;
    }
  }

  private ownedByMe(): boolean {
    const user = SessionStore.getUser();
    return !!user?.id && !!this.pet && this.pet.ownerId === user.id;
  }

  private async submitAdoptionRequest(): Promise<void> {
    if (!this.pet || !this.petId) {
      return;
    }
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      AppRouter.replace('pages/Login');
      return;
    }
    if ((this.pet.adoptionStatus ?? 'AVAILABLE') !== 'AVAILABLE') {
      AppPrompt.toast('当前暂不开放领养申请');
      return;
    }
    if (!this.adoptContactPhone.trim()) {
      this.errorText = '请填写联系电话';
      return;
    }
    this.adoptSubmitting = true;
    this.errorText = '';
    try {
      await Api.createAdoptionRequest(this.petId, {
        message: this.adoptMessage.trim(),
        contactName: this.adoptContactName.trim(),
        contactPhone: this.adoptContactPhone.trim()
      });
      const appended: PetMessage = {
        id: Date.now(),
        petId: this.petId,
        authorName: this.adoptContactName.trim() || '新访客',
        content: this.adoptMessage.trim() || '已提交领养申请，希望进一步了解宠物情况。',
        createdAt: new Date().toISOString()
      };
      this.messages = [appended, ...this.messages];
      this.adoptMessage = '';
      AppPrompt.toast('已提交领养申请');
    } catch (e) {
      this.errorText = (e as Error).message || '提交失败';
    } finally {
      this.adoptSubmitting = false;
    }
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Image($r('app.media.hero_back'))
          .width(24)
          .height(24)
          .onClick(() => AppRouter.back())
        Blank()
        Text('领养详情')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text(this.pet ? adoptionStatusLabel(this.pet.adoptionStatus) : '')
          .fontSize(12)
          .fontColor(Theme.primary)
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .width('100%')
      .backgroundColor(Color.White)

      Scroll() {
        Column({ space: 16 }) {
          if (this.errorText) {
            Text(this.errorText)
              .fontSize(13)
              .fontColor('#D14343')
              .padding(16)
          }

          if (this.pet) {
            Stack({ alignContent: Alignment.BottomStart }) {
              Image(MediaAssets.petImage(this.pet.image, this.pet.id ?? 0, this.pet.species))
                .width('100%')
                .height(300)
                .borderRadius(28)
                .objectFit(ImageFit.Cover)
              Column({ space: 8 }) {
                Text(this.pet.name)
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                Text(`${this.pet.species} · ${this.pet.breed ?? '品种待补充'} · ${petGenderLabel(this.pet.gender)} · ${this.pet.age ?? '-'} 岁`)
                  .fontSize(13)
                  .fontColor('#F8FAFC')
              }
              .padding(18)
              .width('100%')
              .linearGradient({ angle: 180, colors: [['#11182700', 0], ['#111827C0', 1]] })
              .borderRadius(28)
            }

            Column({ space: 12 }) {
              Row({ space: 8 }) {
                Text(adoptionStatusLabel(this.pet.adoptionStatus))
                  .fontSize(11)
                  .fontColor(Theme.primary)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor('#E8F1FF')
                  .borderRadius(12)
                if (this.pet.adoptionCity) {
                  Text(`所在城市：${this.pet.adoptionCity}`)
                    .fontSize(11)
                    .fontColor('#FF8A3D')
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .backgroundColor('#FFF3E0')
                    .borderRadius(12)
                }
              }
              Text('基本信息')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.textPrimary)
              Text(`品种：${this.pet.breed ?? '待补充'}\n性别：${petGenderLabel(this.pet.gender)}\n年龄：${this.pet.age ?? '-'} 岁\n状态：${adoptionStatusLabel(this.pet.adoptionStatus)}`)
                .fontSize(13)
                .lineHeight(22)
                .fontColor(Theme.textSecondary)
              Text('宠物描述')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.textPrimary)
              Text(this.pet.description ?? '暂无描述')
                .fontSize(14)
                .lineHeight(22)
                .fontColor(Theme.textPrimary)
              if (this.pet.adoptionNote) {
                Text('主人寄语')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.textPrimary)
                Text(this.pet.adoptionNote)
                  .fontSize(13)
                  .lineHeight(20)
                  .fontColor('#FF8A3D')
                  .padding(14)
                  .backgroundColor('#FFF3E0')
                  .borderRadius(16)
              }
            }
            .padding(18)
            .backgroundColor(Color.White)
            .borderRadius(24)

            Column({ space: 12 }) {
              Text('用户留言')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.textPrimary)
              ForEach(this.messages, (message: PetMessage) => {
                Column({ space: 6 }) {
                  Row() {
                    Text(message.authorName)
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Theme.textPrimary)
                    Blank()
                    Text(relativeTime(message.createdAt))
                      .fontSize(11)
                      .fontColor(Theme.textMuted)
                  }
                  .width('100%')
                  Text(message.content)
                    .fontSize(13)
                    .lineHeight(20)
                    .fontColor(Theme.textSecondary)
                }
                .padding(14)
                .backgroundColor(Theme.surfaceMuted)
                .borderRadius(16)
              }, (message: PetMessage) => String(message.id))
            }
            .padding(18)
            .backgroundColor(Color.White)
            .borderRadius(24)

            if (this.ownedByMe()) {
              Column({ space: 12 }) {
                Text('档案与领养管理')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                Button('查看健康档案')
                  .height(44)
                  .width('100%')
                  .backgroundColor(Theme.primary)
                  .fontColor(Color.White)
                  .borderRadius(16)
                  .onClick(() => AppRouter.push('pages/HealthRecords', { petId: this.petId } as PetRouteParams))
                Button('查看领养申请')
                  .height(44)
                  .width('100%')
                  .backgroundColor('#E8F1FF')
                  .fontColor(Theme.primary)
                  .borderRadius(16)
                  .onClick(() => AppRouter.push('pages/AdoptionRequests', { petId: this.petId } as PetRouteParams))
              }
              .padding(18)
              .backgroundColor(Color.White)
              .borderRadius(24)
            } else {
              Column({ space: 12 }) {
                Text('提交领养留言')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                TextInput({ placeholder: '你的名字（可选）', text: this.adoptContactName })
                  .height(40)
                  .backgroundColor('#F6F8FC')
                  .borderRadius(12)
                  .border({ width: 0 })
                  .padding({ left: 12, right: 12 })
                  .onChange((v: string) => this.adoptContactName = v)
                TextInput({ placeholder: '联系电话', text: this.adoptContactPhone })
                  .height(40)
                  .backgroundColor('#F6F8FC')
                  .borderRadius(12)
                  .border({ width: 0 })
                  .padding({ left: 12, right: 12 })
                  .onChange((v: string) => this.adoptContactPhone = v)
                TextArea({ placeholder: '留言说明你的养宠经验、居住环境和领养计划', text: this.adoptMessage })
                  .height(96)
                  .backgroundColor('#F6F8FC')
                  .borderRadius(12)
                  .border({ width: 0 })
                  .padding(12)
                  .onChange((v: string) => this.adoptMessage = v)
                Button(this.adoptSubmitting ? '提交中…' : '提交领养申请')
                  .height(44)
                  .width('100%')
                  .backgroundColor('#FF7AA2')
                  .fontColor(Color.White)
                  .borderRadius(16)
                  .enabled(!this.adoptSubmitting)
                  .onClick(() => this.submitAdoptionRequest())
              }
              .padding(18)
              .backgroundColor(Color.White)
              .borderRadius(24)
            }
          } else if (this.loading) {
            Text('加载中…')
              .fontSize(14)
              .fontColor('#999')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(40)
          }
        }
        .padding(16)
      }
      .layoutWeight(1)
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }
}
