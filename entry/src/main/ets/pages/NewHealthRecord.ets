import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { PrimaryButton, Field, ErrorText, SectionTitle, OptionGroup } from '../components/Ui';
import { HealthRecord, HealthRecordType } from '../model/Models';

interface PetIdParams {
  petId?: number;
}

const TYPES: HealthRecordType[] = ['VACCINATION', 'EXAMINATION', 'TREATMENT', 'MEDICATION', 'GROOMING'];

@Entry
@Component
struct NewHealthRecord {
  @State private petId: number = 0;
  @State private recordType: HealthRecordType = 'EXAMINATION';
  @State private title: string = '';
  @State private description: string = '';
  @State private recordDate: string = '';
  @State private nextDueDate: string = '';
  @State private veterinarian: string = '';
  @State private loading: boolean = false;
  @State private errorText: string = '';

  aboutToAppear(): void {
    const params = AppRouter.params<PetIdParams>();
    this.petId = Number(params?.petId ?? 0);
    const today = new Date();
    const y = String(today.getFullYear());
    const m = String(today.getMonth() + 1).padStart(2, '0');
    const d = String(today.getDate()).padStart(2, '0');
    this.recordDate = `${y}-${m}-${d}`;
  }

  private async submit(): Promise<void> {
    if (!this.petId) {
      this.errorText = '无效宠物';
      return;
    }
    if (!this.recordDate) {
      this.errorText = '请填写日期';
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      await Api.createHealthRecord({
        petId: this.petId,
        recordType: this.recordType,
        title: this.title.trim(),
        description: this.description.trim(),
        recordDate: this.recordDate,
        nextDueDate: this.nextDueDate.trim() || undefined,
        veterinarian: this.veterinarian.trim() || undefined
      });
      AppRouter.back();
    } catch (e) {
      this.errorText = (e as Error).message || '创建失败';
    } finally {
      this.loading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Row() {
          Text('新增健康记录').fontSize(18).fontWeight(FontWeight.Bold)
          Blank()
          Text('返回').fontSize(14).fontColor('#2B7FFF').onClick(() => AppRouter.back())
        }

        SectionTitle({ title: '类型' })
        OptionGroup({
          label: '选择类型',
          options: TYPES,
          selected: this.recordType,
          onSelect: (v: string) => this.recordType = v as HealthRecordType
        })

        SectionTitle({ title: '内容' })
        Field({
          label: '标题',
          placeholder: '可选',
          value: this.title,
          onChange: (v: string) => this.title = v
        })
        Column({ space: 6 }) {
          Text('描述').fontSize(13).fontColor('#444')
          TextArea({ placeholder: '症状/处置/用药等', text: this.description })
            .height(140)
            .backgroundColor('#F6F7F9')
            .borderRadius(10)
            .padding(12)
            .onChange((v: string) => this.description = v)
        }.width('100%')
        Field({
          label: '记录日期',
          placeholder: 'YYYY-MM-DD',
          value: this.recordDate,
          onChange: (v: string) => this.recordDate = v
        })
        Field({
          label: '下次到期日期',
          placeholder: 'YYYY-MM-DD（可选）',
          value: this.nextDueDate,
          onChange: (v: string) => this.nextDueDate = v
        })
        Field({
          label: '兽医',
          placeholder: '可选',
          value: this.veterinarian,
          onChange: (v: string) => this.veterinarian = v
        })

        ErrorText({ text: this.errorText })
        PrimaryButton({ text: this.loading ? '提交中…' : '保存', disabled: this.loading, action: () => this.submit() })
      }
      .padding(16)
      .width('100%')
    }
    .height('100%')
    .width('100%')
  }
}
