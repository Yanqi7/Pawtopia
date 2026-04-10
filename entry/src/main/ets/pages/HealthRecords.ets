import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { HealthRecord, Pet } from '../model/Models';
import { EmptyState, ErrorText, OfflineBanner, SectionTitle } from '../components/Ui';
import { MediaAssets } from '../assets/MediaAssets';
import { Theme } from '../common/Theme';
import { healthRecordTypeLabel, shortDate } from '../common/Formatters';
import { SessionStore } from '../store/SessionStore';

interface PetIdParams {
  petId?: number;
}

@Entry
@Component
struct HealthRecords {
  @State private petId: number = 0;
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private records: HealthRecord[] = [];
  @State private pet?: Pet = undefined;

  private canEdit(): boolean {
    const user = SessionStore.getUser();
    if (!user || !this.pet) {
      return false;
    }
    return user.role === 'ADMIN' || user.role === 'PET_HOSPITAL' || this.pet.ownerId === user.id;
  }

  aboutToAppear(): void {
    const params = AppRouter.params<PetIdParams>();
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
      this.records = await Api.getHealthRecordsByPet(this.petId);
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('健康档案').fontSize(18).fontWeight(FontWeight.Bold)
        Blank()
        Button('新增')
          .height(32)
          .borderRadius(16)
          .backgroundColor(this.canEdit() ? Theme.primary : '#D7DDE7')
          .fontColor(Color.White)
          .enabled(this.canEdit())
          .onClick(() => AppRouter.push('pages/NewHealthRecord', { petId: this.petId } as PetIdParams))
        Text('返回')
          .fontSize(14)
          .fontColor(Theme.primary)
          .margin({ left: 10 })
          .onClick(() => AppRouter.back())
      }
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      if (this.errorText) {
        ErrorText({ text: this.errorText })
      }

      if (!this.loading && this.pet) {
        Row({ space: 8 }) {
          Image($r('app.media.hero_bell'))
            .width(18)
            .height(18)
          Text(this.canEdit()
            ? (SessionStore.getUser()?.role === 'PET_HOSPITAL'
              ? '宠物医院账号可维护健康记录；请确保记录与实际就诊情况一致。'
              : '你可以维护这只宠物的健康档案与护理记录。')
            : '当前账号只能查看该宠物的健康档案，若需维护记录请切换到宠物主人、医院或管理员账号。')
            .fontSize(12)
            .fontColor(Theme.textSecondary)
            .layoutWeight(1)
        }
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor('#EEF5FF')
        .borderRadius(12)
        .border({ width: 1, color: '#D9E8FF' })
        .margin({ left: 16, right: 16, bottom: 8 })
      }

      if (!this.loading && this.records.length === 0) {
        EmptyState({
          title: '还没有健康档案',
          description: this.canEdit() ? '先添加一条体检、疫苗或护理记录，后续可以在这里持续维护。' : '当前账号只能查看该宠物档案，暂无可显示的健康记录。',
          actionText: this.canEdit() ? '新增记录' : '',
          action: () => this.canEdit() ? AppRouter.push('pages/NewHealthRecord', { petId: this.petId } as PetIdParams) : undefined
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
                  Text(`${this.pet.name} 的健康档案`)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                  Text(`${this.pet.species} · ${this.pet.breed ?? '待补充'} · 最近维护 ${shortDate(this.records[0]?.recordDate ?? this.pet.updatedAt)}`)
                    .fontSize(12)
                    .fontColor('#F8FAFC')
                }
                .width('100%')
                .padding(16)
                .linearGradient({ angle: 180, colors: [['#11182700', 0], ['#111827B8', 1]] })
                .borderRadius(24)
              }
            }

            SectionTitle({ title: `记录时间线（${this.records.length}）` })
            ForEach(this.records, (record: HealthRecord) => {
              Row({ space: 12 }) {
                Column()
                  .width(10)
                  .height(10)
                  .borderRadius(5)
                  .backgroundColor(Theme.primary)
                  .margin({ top: 6 })
                Column({ space: 8 }) {
                  Row({ space: 8 }) {
                    Text(record.title ?? healthRecordTypeLabel(record.recordType))
                      .fontSize(15)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Theme.textPrimary)
                      .layoutWeight(1)
                    Text(healthRecordTypeLabel(record.recordType))
                      .fontSize(11)
                      .fontColor('#FF8A3D')
                      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                      .backgroundColor('#FFF1E8')
                      .borderRadius(10)
                  }
                  Text(`日期：${record.recordDate}  ${record.veterinarian ?? ''}`)
                    .fontSize(12)
                    .fontColor(Theme.textSecondary)
                  if (record.nextDueDate) {
                    Text(`下次提醒：${record.nextDueDate}`)
                      .fontSize(12)
                      .fontColor('#22A06B')
                  }
                  Text(record.description ?? '无描述')
                    .fontSize(13)
                    .lineHeight(20)
                    .fontColor(Theme.textPrimary)
                }
                .layoutWeight(1)
              }
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(22)
            }, (record: HealthRecord) => String(record.id))

            if (this.loading) {
              Row({ space: 8 }) {
                LoadingProgress().width(20).height(20).color(Theme.primary)
                Text('正在同步健康档案…').fontSize(12).fontColor(Theme.textMuted)
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
