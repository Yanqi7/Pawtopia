import { AppPrompt } from '../common/AppPrompt';
import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Pet } from '../model/Models';
import { SessionStore } from '../store/SessionStore';

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

  aboutToAppear(): void {
    const params = AppRouter.params<IdParams>();
    this.petId = Number(params?.id ?? 0);
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
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private ownedByMe(): boolean {
    const u = SessionStore.getUser();
    if (!u || !u.id || !this.pet) {
      return false;
    }
    return this.pet.ownerId === u.id;
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
      this.adoptMessage = '';
      this.adoptContactName = '';
      this.adoptContactPhone = '';
      AppPrompt.toast('已提交领养申请');
    } catch (e) {
      this.errorText = (e as Error).message || '提交失败';
    } finally {
      this.adoptSubmitting = false;
    }
  }

  build() {
    Column() {
      // 顶部导航
      Row({ space: 12 }) {
        Image($r('app.media.more'))
          .width(24)
          .height(24)
          .fillColor('#2B7FFF')
          .onClick(() => AppRouter.back())
        Blank()
        Text('宠物详情')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Blank()
        Image($r('app.media.like'))
          .width(24)
          .height(24)
          .fillColor('#FF69B4')
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .width('100%')
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: '#F0F0F0' })

      Scroll() {
        Column({ space: 16 }) {
          if (this.errorText) {
            Text(this.errorText)
              .fontSize(13)
              .fontColor(Color.Red)
              .padding(16)
          }

          if (this.pet) {
            // 宠物图片
            Stack() {
              Image(this.pet!.image ? $r(`app.media.${this.pet!.image}`) : $r('app.media.dog'))
                .width('100%')
                .height(240)
                .objectFit(ImageFit.Cover)
              Row() {
                Blank()
                Column() {
                  Text('👑')
                    .fontSize(28)
                }
                .width(50)
                .height(50)
                .backgroundColor('#FFE8F0')
                .borderRadius(25)
                .alignItems(HorizontalAlign.Center)
                .justifyContent(FlexAlign.Center)
              }
              .width('100%')
              .padding(12)
            }
            .width('100%')

            // 宠物基本信息
            Column({ space: 12 }) {
              Text(`${this.pet!.name}（${this.pet!.species}）`)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)

              Row({ space: 20 }) {
                Column({ space: 4 }) {
                  Text('品种')
                    .fontSize(12)
                    .fontColor('#999')
                  Text(this.pet!.breed ?? '未知')
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                }
                .alignItems(HorizontalAlign.Center)

                Column({ space: 4 }) {
                  Text('年龄')
                    .fontSize(12)
                    .fontColor('#999')
                  Text(`${this.pet!.age ?? '-'}岁`)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                }
                .alignItems(HorizontalAlign.Center)

                Column({ space: 4 }) {
                  Text('性别')
                    .fontSize(12)
                    .fontColor('#999')
                  Text(this.pet!.gender === 'MALE' ? '公' : this.pet!.gender === 'FEMALE' ? '母' : '未知')
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                }
                .alignItems(HorizontalAlign.Center)
              }
              .width('100%')
              .backgroundColor('#F9F9F9')
              .borderRadius(8)
              .padding(12)

              Text(this.pet!.description ?? '暂无描述')
                .fontSize(14)
                .fontColor('#333')
                .width('100%')
                .lineHeight(1.6)

              if (this.pet!.adoptionNote) {
                Row() {
                  Text('💡')
                    .fontSize(14)
                    .margin({ right: 8 })
                  Text(this.pet!.adoptionNote)
                    .fontSize(12)
                    .fontColor('#FF9D4E')
                    .layoutWeight(1)
                }
                .backgroundColor('#FFF3E0')
                .borderRadius(8)
                .padding(12)
              }
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)

            if (this.ownedByMe()) {
              Column({ space: 12 }) {
                Text('健康档案')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)

                Button('查看健康档案')
                  .height(44)
                  .width('100%')
                  .backgroundColor('#2B7FFF')
                  .fontColor(Color.White)
                  .borderRadius(8)
                  .onClick(() => AppRouter.push('pages/HealthRecords', { petId: this.petId } as PetRouteParams))

                Text('领养管理')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 8 })

                Button('查看领养申请')
                  .height(44)
                  .width('100%')
                  .backgroundColor('#F0F2F5')
                  .fontColor('#2B7FFF')
                  .borderRadius(8)
                  .onClick(() => AppRouter.push('pages/AdoptionRequests', { petId: this.petId } as PetRouteParams))
              }
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(12)
            } else {
              Column({ space: 12 }) {
                Text('申请领养')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)

                Text('提交后宠物主人会看到你的申请')
                  .fontSize(12)
                  .fontColor('#666')

                TextInput({ placeholder: '你的名字（可选）', text: this.adoptContactName })
                  .height(40)
                  .backgroundColor('#F9F9F9')
                  .border({ width: 1, color: '#E8E8E8' })
                  .borderRadius(8)
                  .padding({ left: 12, right: 12 })
                  .onChange((v: string) => this.adoptContactName = v)

                TextInput({ placeholder: '联系电话', text: this.adoptContactPhone })
                  .height(40)
                  .backgroundColor('#F9F9F9')
                  .border({ width: 1, color: '#E8E8E8' })
                  .borderRadius(8)
                  .padding({ left: 12, right: 12 })
                  .onChange((v: string) => this.adoptContactPhone = v)

                TextArea({ placeholder: '说说你为什么想领养这只宠物...', text: this.adoptMessage })
                  .height(80)
                  .backgroundColor('#F9F9F9')
                  .border({ width: 1, color: '#E8E8E8' })
                  .borderRadius(8)
                  .padding(12)
                  .onChange((v: string) => this.adoptMessage = v)

                Button(this.adoptSubmitting ? '提交中…' : '提交领养申请')
                  .height(44)
                  .width('100%')
                  .backgroundColor('#FF69B4')
                  .fontColor(Color.White)
                  .borderRadius(8)
                  .enabled(!this.adoptSubmitting)
                  .onClick(() => this.submitAdoptionRequest())
              }
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(12)
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
    .backgroundColor('#F5F5F5')
  }
}
