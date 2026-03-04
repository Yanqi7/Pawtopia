import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Api } from '../api/Api';
import { Pet } from '../model/Models';
import { SessionStore } from '../store/SessionStore';
import { ErrorText, Field, PrimaryButton, SectionTitle } from '../components/Ui';

interface IdParams {
  id?: number;
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
    const params = router.getParams() as IdParams;
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
      router.replaceUrl({ url: 'pages/Login' });
      return;
    }
    if ((this.pet.adoptionStatus ?? 'AVAILABLE') !== 'AVAILABLE') {
      promptAction.showToast({ message: '当前暂不开放领养申请' });
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
      promptAction.showToast({ message: '已提交领养申请' });
    } catch (e) {
      this.errorText = (e as Error).message || '提交失败';
    } finally {
      this.adoptSubmitting = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Row() {
          Text('宠物详情').fontSize(18).fontWeight(FontWeight.Bold)
          Blank()
          Text('返回').fontSize(14).fontColor('#2B7FFF').onClick(() => router.back())
        }

        if (this.errorText) {
          ErrorText({ text: this.errorText })
        }

        if (this.pet) {
          Column({ space: 8 }) {
            Text(`${this.pet!.name}（${this.pet!.species}）`).fontSize(18).fontWeight(FontWeight.Bold)
            Text(`品种：${this.pet!.breed ?? '-'}  年龄：${this.pet!.age ?? '-'}  性别：${this.pet!.gender ?? '-'}`)
              .fontSize(13)
              .fontColor('#666')
            Text(`领养：${this.pet!.adoptionStatus ?? 'AVAILABLE'}  城市：${this.pet!.adoptionCity ?? '-'}`)
              .fontSize(12)
              .fontColor('#999')
            Text(this.pet!.description ?? '暂无描述').fontSize(14).fontColor('#333')
            if (this.pet!.adoptionNote) {
              Text(`备注：${this.pet!.adoptionNote}`).fontSize(12).fontColor('#666')
            }
          }
          .padding(12)
          .backgroundColor('#F6F7F9')
          .borderRadius(12)

          if (this.ownedByMe()) {
            SectionTitle({ title: '健康档案' })
            Button('查看健康档案')
              .height(44)
              .width('100%')
              .borderRadius(10)
              .backgroundColor('#2B7FFF')
              .fontColor(Color.White)
              .onClick(() => router.pushUrl({ url: 'pages/HealthRecords', params: { petId: this.petId } }))

            SectionTitle({ title: '领养管理' })
            Button('查看领养申请')
              .height(44)
              .width('100%')
              .borderRadius(10)
              .backgroundColor('#F0F2F5')
              .onClick(() => router.pushUrl({ url: 'pages/AdoptionRequests', params: { petId: this.petId } }))
          } else {
            SectionTitle({ title: '申请领养' })
            Text('提交后宠物主人会看到你的申请。').fontSize(12).fontColor('#666')
            Field({
              label: '联系人（可选）',
              placeholder: '你的称呼',
              value: this.adoptContactName,
              onChange: (v: string) => this.adoptContactName = v
            })
            Field({
              label: '联系电话',
              placeholder: '用于联系（必填）',
              value: this.adoptContactPhone,
              onChange: (v: string) => this.adoptContactPhone = v,
              type: InputType.PhoneNumber
            })
            Column({ space: 6 }) {
              Text('申请说明（可选）').fontSize(13).fontColor('#444')
              TextArea({ placeholder: '简单介绍一下你的情况与领养计划', text: this.adoptMessage })
                .height(120)
                .backgroundColor('#F6F7F9')
                .borderRadius(10)
                .padding(12)
                .onChange((v: string) => this.adoptMessage = v)
            }.width('100%')
            PrimaryButton({ text: this.adoptSubmitting ? '提交中…' : '提交领养申请', disabled: this.adoptSubmitting, action: () => this.submitAdoptionRequest() })
          }
        } else if (this.loading) {
          Text('加载中…').fontSize(13).fontColor('#666')
        }
      }
      .padding(16)
      .width('100%');
    }
    .height('100%')
    .width('100%')
  }
}
