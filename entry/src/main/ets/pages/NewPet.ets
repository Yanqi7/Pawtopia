import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { PrimaryButton, Field, ErrorText, SectionTitle, OptionGroup, TopBar } from '../components/Ui';
import { SessionStore } from '../store/SessionStore';
import { Pet, PetGender } from '../model/Models';
import { Theme } from '../common/Theme';
import { MediaAssets } from '../assets/MediaAssets';

const GENDERS: PetGender[] = ['MALE', 'FEMALE'];
const IMAGE_KEYS: string[] = [
  'pet_dog_real_1',
  'pet_dog_real_2',
  'pet_dog_real_3',
  'pet_dog_real_4',
  'pet_cat_real_1',
  'pet_cat_real_2',
  'pet_cat_real_3',
  'pet_cat_real_4'
];

type PetCreateMode = 'ADOPT' | 'PROFILE';

interface Params {
  mode?: PetCreateMode;
}

@Entry
@Component
struct NewPet {
  @State private mode: PetCreateMode = 'ADOPT';
  @State private name: string = '';
  @State private species: string = '';
  @State private breed: string = '';
  @State private age: string = '';
  @State private gender: PetGender = 'MALE';
  @State private description: string = '';
  @State private imageKey: string = IMAGE_KEYS[0];
  @State private imageUrlInput: string = '';
  @State private adoptionCity: string = '';
  @State private adoptionNote: string = '';
  @State private loading: boolean = false;
  @State private errorText: string = '';

  aboutToAppear(): void {
    AppRouter.bind(this);
    const params = AppRouter.params<Params>(this);
    this.mode = params?.mode === 'PROFILE' ? 'PROFILE' : 'ADOPT';
  }

  private async submit(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      AppRouter.replace('pages/Login', undefined, this);
      return;
    }
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
        image: this.imageUrlInput.trim() || this.imageKey,
        adoptionStatus: this.mode === 'PROFILE' ? 'PAUSED' : 'AVAILABLE',
        adoptionCity: this.mode === 'PROFILE' ? undefined : this.adoptionCity.trim(),
        adoptionNote: this.mode === 'PROFILE' ? undefined : this.adoptionNote.trim(),
        ownerId: user.id
      } as Pet);
      AppRouter.back(this);
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '创建失败';
    } finally {
      this.loading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        TopBar({
          title: this.mode === 'PROFILE' ? '添加宠物' : '发布领养',
          subtitle: this.mode === 'PROFILE' ? '先录入基础资料，后续再维护健康记录。' : '创建一只待领养宠物，并补齐领养城市与要求。',
          onBack: () => AppRouter.back(this)
        })

        SectionTitle({ title: '基本信息' })
        Field({ label: '名称', placeholder: '例如：团子', value: this.name, onChange: (v: string) => this.name = v })
        Field({ label: '物种', placeholder: '例如：猫 / 狗', value: this.species, onChange: (v: string) => this.species = v })
        Field({ label: '品种', placeholder: '可选', value: this.breed, onChange: (v: string) => this.breed = v })
        Field({ label: '年龄', placeholder: '可选', value: this.age, onChange: (v: string) => this.age = v, type: InputType.Number })

        SectionTitle({ title: '性别' })
        OptionGroup({
          label: '选择性别',
          options: GENDERS.map((g: PetGender) => g === 'MALE' ? '公' : '母'),
          selected: this.gender === 'MALE' ? '公' : '母',
          onSelect: (value: string) => this.gender = value === '公' ? 'MALE' : 'FEMALE'
        })

        SectionTitle({ title: '头像/封面' })
        Image(MediaAssets.petImage(this.imageUrlInput.trim() || this.imageKey, 0, this.species))
          .width('100%')
          .height(220)
          .borderRadius(24)
          .objectFit(ImageFit.Cover)
        Field({
          label: '图片链接',
          placeholder: '支持 https://... 或多个链接用逗号分隔',
          value: this.imageUrlInput,
          onChange: (v: string) => {
            this.imageUrlInput = v;
            this.imageKey = v.trim() || IMAGE_KEYS[0];
          }
        })
        Row({ space: 8 }) {
          ForEach(IMAGE_KEYS, (key: string) => {
            Image(MediaAssets.petImage(key))
              .width(60)
              .height(60)
              .borderRadius(12)
              .border({ width: this.imageKey === key ? 2 : 1, color: this.imageKey === key ? Theme.primary : Theme.border })
              .onClick(() => {
                this.imageKey = key;
                this.imageUrlInput = key;
              })
          }, (key: string) => key)
        }

        SectionTitle({ title: '描述' })
        Column({ space: 6 }) {
          Text('简介')
            .fontSize(13)
            .fontColor(Theme.textSecondary)
          TextArea({ placeholder: '性格、习惯、领养说明等', text: this.description })
            .height(140)
            .backgroundColor('#F6F7F9')
            .border({ width: 1, color: Theme.border })
            .borderRadius(12)
            .padding(12)
            .onChange((v: string) => this.description = v)
        }
        .width('100%')

        if (this.mode !== 'PROFILE') {
          SectionTitle({ title: '领养信息' })
          Field({ label: '城市', placeholder: '例如：北京', value: this.adoptionCity, onChange: (v: string) => this.adoptionCity = v })
          Field({ label: '领养要求', placeholder: '例如：封窗、稳定居住、接受回访（可选）', value: this.adoptionNote, onChange: (v: string) => this.adoptionNote = v })
        }

        ErrorText({ text: this.errorText })
        PrimaryButton({ text: this.loading ? '提交中…' : '保存', disabled: this.loading, action: () => this.submit() })
      }
      .padding(16)
      .width('100%')
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }
}
