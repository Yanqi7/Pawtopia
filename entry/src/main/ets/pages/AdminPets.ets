import { Api } from '../api/Api';
import { AppPrompt } from '../common/AppPrompt';
import { AppRouter } from '../common/AppRouter';
import { Theme } from '../common/Theme';
import { Field, OptionGroup, SectionHeader, TopBar } from '../components/Ui';
import { Pet, PetGender } from '../model/Models';
import { SessionStore } from '../store/SessionStore';
import { MediaAssets } from '../assets/MediaAssets';

interface Params {
  mode?: 'PROFILE' | 'ADOPT';
}

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

@Entry
@Component
struct AdminPets {
  @State private mode: 'PROFILE' | 'ADOPT' = 'PROFILE';
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private pets: Pet[] = [];
  @State private selected?: Pet = undefined;

  @State private name: string = '';
  @State private species: string = '';
  @State private breed: string = '';
  @State private age: string = '';
  @State private gender: PetGender = 'MALE';
  @State private description: string = '';
  @State private adoptionCity: string = '';
  @State private adoptionNote: string = '';
  @State private adoptionStatus: 'AVAILABLE' | 'PAUSED' | 'ADOPTED' = 'AVAILABLE';
  @State private imageKey: string = IMAGE_KEYS[0];

  aboutToAppear(): void {
    AppRouter.bind(this);
    const params = AppRouter.params<Params>(this);
    this.mode = params?.mode === 'ADOPT' ? 'ADOPT' : 'PROFILE';
    this.load();
  }

  private isAdmin(): boolean {
    return SessionStore.getUser()?.role === 'ADMIN';
  }

  private async load(): Promise<void> {
    if (!this.isAdmin()) {
      this.errorText = '仅管理员可访问该页面';
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      const pets = await Api.getAllPets();
      this.pets = pets;
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private setForm(pet: Pet): void {
    this.selected = pet;
    this.name = pet.name ?? '';
    this.species = pet.species ?? '';
    this.breed = pet.breed ?? '';
    this.age = pet.age ? String(pet.age) : '';
    this.gender = (pet.gender ?? 'MALE') as PetGender;
    this.description = pet.description ?? '';
    this.adoptionCity = pet.adoptionCity ?? '';
    this.adoptionNote = pet.adoptionNote ?? '';
    this.adoptionStatus = (pet.adoptionStatus ?? 'AVAILABLE') as 'AVAILABLE' | 'PAUSED' | 'ADOPTED';
    this.imageKey = pet.image ?? IMAGE_KEYS[0];
  }

  private async save(): Promise<void> {
    if (!this.selected?.id) {
      return;
    }
    const payload: Pet = {
      id: this.selected.id,
      name: this.name.trim(),
      species: this.species.trim(),
      breed: this.breed.trim() || undefined,
      age: this.age ? Number(this.age) : undefined,
      gender: this.gender,
      description: this.description.trim() || undefined,
      adoptionCity: this.mode === 'ADOPT' ? this.adoptionCity.trim() : undefined,
      adoptionNote: this.mode === 'ADOPT' ? this.adoptionNote.trim() : undefined,
      adoptionStatus: this.mode === 'ADOPT' ? this.adoptionStatus : this.selected.adoptionStatus,
      image: this.imageKey,
      ownerId: this.selected.ownerId
    } as Pet;
    try {
      await Api.updatePet(this.selected.id, payload);
      AppPrompt.toast('宠物信息已更新', this);
      await this.load();
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '更新失败';
    }
  }

  build() {
    Column() {
      TopBar({
        title: this.mode === 'ADOPT' ? '领养信息管理' : '宠物档案管理',
        subtitle: '管理员可编辑所有宠物档案与领养信息。',
        onBack: () => AppRouter.back(this)
      })

      if (this.errorText) {
        Text(this.errorText)
          .fontSize(12)
          .fontColor(Theme.danger)
          .padding({ left: 16, right: 16, bottom: 8 })
      }

      Scroll() {
        Column({ space: 12 }) {
          SectionHeader({ title: '宠物列表', subtitle: `共 ${this.pets.length} 条记录` })

          ForEach(this.pets, (pet: Pet) => {
            Row({ space: 12 }) {
              Image(MediaAssets.petImage(pet.image, pet.id ?? 0, pet.species))
                .width(72)
                .height(72)
                .borderRadius(12)
                .objectFit(ImageFit.Cover)
              Column({ space: 4 }) {
                Text(pet.name)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.textPrimary)
                Text(`${pet.species} · ${pet.breed ?? '未设置'} · ${pet.gender ?? ''}`)
                  .fontSize(12)
                  .fontColor(Theme.textSecondary)
                if (this.mode === 'ADOPT') {
                  Text(`状态：${pet.adoptionStatus ?? 'AVAILABLE'} · 城市：${pet.adoptionCity ?? '-'}`)
                    .fontSize(11)
                    .fontColor(Theme.textMuted)
                }
              }
              .layoutWeight(1)
              Text('编辑')
                .fontSize(12)
                .fontColor(Theme.primary)
                .onClick(() => this.setForm(pet))
            }
            .padding(12)
            .backgroundColor(Color.White)
            .borderRadius(16)
          }, (pet: Pet) => String(pet.id))

          if (this.selected) {
            SectionHeader({ title: '编辑信息', subtitle: this.mode === 'ADOPT' ? '更新公开领养信息' : '更新档案信息' })
            Row({ space: 8 }) {
              ForEach(IMAGE_KEYS, (key: string) => {
                Image(MediaAssets.petImage(key))
                  .width(60)
                  .height(60)
                  .borderRadius(12)
                  .border({ width: this.imageKey === key ? 2 : 1, color: this.imageKey === key ? Theme.primary : Theme.border })
                  .onClick(() => this.imageKey = key)
              }, (key: string) => key)
            }

            Field({ label: '名称', placeholder: '', value: this.name, onChange: (v: string) => this.name = v })
            Field({ label: '物种', placeholder: '', value: this.species, onChange: (v: string) => this.species = v })
            Field({ label: '品种', placeholder: '', value: this.breed, onChange: (v: string) => this.breed = v })
            Field({ label: '年龄', placeholder: '', value: this.age, onChange: (v: string) => this.age = v, type: InputType.Number })
            OptionGroup({
              label: '性别',
              options: GENDERS.map((g: PetGender) => g === 'MALE' ? '公' : '母'),
              selected: this.gender === 'MALE' ? '公' : '母',
              onSelect: (value: string) => this.gender = value === '公' ? 'MALE' : 'FEMALE'
            })
            Field({ label: '描述', placeholder: '', value: this.description, onChange: (v: string) => this.description = v })

            if (this.mode === 'ADOPT') {
              Field({ label: '领养城市', placeholder: '', value: this.adoptionCity, onChange: (v: string) => this.adoptionCity = v })
              Field({ label: '领养要求', placeholder: '', value: this.adoptionNote, onChange: (v: string) => this.adoptionNote = v })
              OptionGroup({
                label: '领养状态',
                options: ['可领养', '暂停', '已领养'],
                selected: this.adoptionStatus === 'AVAILABLE' ? '可领养' : this.adoptionStatus === 'PAUSED' ? '暂停' : '已领养',
                onSelect: (value: string) => {
                  this.adoptionStatus = value === '可领养' ? 'AVAILABLE' : value === '暂停' ? 'PAUSED' : 'ADOPTED';
                }
              })
            }

            Button('保存修改')
              .height(40)
              .fontSize(14)
              .fontColor(Color.White)
              .backgroundColor(Theme.primary)
              .borderRadius(20)
              .onClick(() => this.save())
          }
        }
        .padding(16)
        .width('100%')
      }
      .layoutWeight(1)
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }
}
