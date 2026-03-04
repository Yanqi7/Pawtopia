import router from '@ohos.router';
import { Api } from '../api/Api';
import { HealthRecord } from '../model/Models';
import { ErrorText, SectionTitle } from '../components/Ui';

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

  aboutToAppear(): void {
    const params = router.getParams() as PetIdParams;
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
          .backgroundColor('#2B7FFF')
          .fontColor(Color.White)
          .onClick(() => router.pushUrl({ url: 'pages/NewHealthRecord', params: { petId: this.petId } }))
        Text('返回')
          .fontSize(14)
          .fontColor('#2B7FFF')
          .margin({ left: 10 })
          .onClick(() => router.back())
      }
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      if (this.errorText) {
        ErrorText({ text: this.errorText })
      }

      List() {
        ForEach(this.records, (r: HealthRecord) => {
          ListItem() {
            Column({ space: 6 }) {
              Text(r.title ?? r.recordType).fontSize(16).fontWeight(FontWeight.Medium)
              Text(`日期：${r.recordDate}  类型：${r.recordType}`).fontSize(12).fontColor('#999')
              if (r.nextDueDate) {
                Text(`下次：${r.nextDueDate}`).fontSize(12).fontColor('#999')
              }
              Text(r.description ?? '无描述').fontSize(13).fontColor('#666').maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .padding(12)
            .backgroundColor('#F6F7F9')
            .borderRadius(12)
          }
          .padding({ left: 16, right: 16, bottom: 10 })
        }, (r: HealthRecord) => String(r.id))

        if (!this.loading && this.records.length === 0) {
          ListItem() {
            Text('暂无记录').fontSize(13).fontColor('#999').width('100%').textAlign(TextAlign.Center).padding(24)
          }
        }
      }
    }
    .height('100%')
    .width('100%')
  }
}
