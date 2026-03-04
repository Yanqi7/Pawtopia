import router from '@ohos.router';
import { Api } from '../api/Api';
import { PrimaryButton, Field, ErrorText, SectionTitle, OptionGroup } from '../components/Ui';
import { SessionStore } from '../store/SessionStore';
import { Pet, PetGender } from '../model/Models';

const GENDERS: PetGender[] = ['MALE', 'FEMALE'];

interface Params {
  mode?: string;
}

@Entry
@Component
struct NewPet {
  @State private mode: string = 'ADOPT';
  @State private name: string = '';
  @State private species: string = '';
  @State private breed: string = '';
  @State private age: string = '';
  @State private gender: PetGender = 'MALE';
  @State private description: string = '';
  @State private adoptionCity: string = '';
  @State private adoptionNote: string = '';
  @State private loading: boolean = false;
  @State private errorText: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Params;
    this.mode = String(params?.mode ?? 'ADOPT');
  }

  private async submit(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      router.replaceUrl({ url: 'pages/Login' });
      return;
    }
    const userId = user.id;
    if (!this.name.trim() || !this.species.trim()) {
      this.errorText = '请填写宠物名称与物种';
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      await Api.createPet({
        name: this.name.trim(),
        species: this.species.trim(),
        breed: this.breed.trim(),
        age: this.age ? Number(this.age) : undefined,
        gender: this.gender,
        description: this.description.trim(),
        adoptionStatus: this.mode === 'MEDICAL' ? 'PAUSED' : 'AVAILABLE',
        adoptionCity: this.mode === 'MEDICAL' ? undefined : this.adoptionCity.trim(),
        adoptionNote: this.mode === 'MEDICAL' ? undefined : this.adoptionNote.trim(),
        ownerId: userId
      });
      router.back();
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
          Text(this.mode === 'MEDICAL' ? '添加宠物' : '发布领养').fontSize(18).fontWeight(FontWeight.Bold)
          Blank()
          Text('返回').fontSize(14).fontColor('#2B7FFF').onClick(() => router.back())
        }

        SectionTitle({ title: '基本信息' })
        Field({
          label: '名称',
          placeholder: '例如：团子',
          value: this.name,
          onChange: (v: string) => this.name = v
        })
        Field({
          label: '物种',
          placeholder: '例如：猫 / 狗',
          value: this.species,
          onChange: (v: string) => this.species = v
        })
        Field({
          label: '品种',
          placeholder: '可选',
          value: this.breed,
          onChange: (v: string) => this.breed = v
        })
        Field({
          label: '年龄',
          placeholder: '可选',
          value: this.age,
          onChange: (v: string) => this.age = v,
          type: InputType.Number
        })

        SectionTitle({ title: '性别' })
        OptionGroup({
          label: '选择性别',
          options: GENDERS.map((g) => g ?? ''),
          selected: this.gender ?? 'MALE',
          onSelect: (v: string) => this.gender = v as PetGender
        })

        SectionTitle({ title: '描述' })
        Column({ space: 6 }) {
          Text('简介').fontSize(13).fontColor('#444')
          TextArea({ placeholder: '性格、习惯、领养说明等', text: this.description })
            .height(140)
            .backgroundColor('#F6F7F9')
            .borderRadius(10)
            .padding(12)
            .onChange((v: string) => this.description = v)
        }.width('100%')

        if (this.mode !== 'MEDICAL') {
          SectionTitle({ title: '领养信息' })
          Field({
            label: '城市',
            placeholder: '例如：北京',
            value: this.adoptionCity,
            onChange: (v: string) => this.adoptionCity = v
          })
          Field({
            label: '领养要求',
            placeholder: '例如：封窗、稳定居住、接受回访（可选）',
            value: this.adoptionNote,
            onChange: (v: string) => this.adoptionNote = v
          })
        }

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
