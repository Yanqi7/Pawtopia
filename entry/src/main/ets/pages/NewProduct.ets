import { Api } from '../api/Api';
import { MediaAssets } from '../assets/MediaAssets';
import { AppPrompt } from '../common/AppPrompt';
import { AppRouter } from '../common/AppRouter';
import { Theme } from '../common/Theme';
import { ErrorText, Field, OptionGroup, PrimaryButton, SectionTitle, TopBar } from '../components/Ui';
import { Product, ProductCategory } from '../model/Models';
import { SessionStore } from '../store/SessionStore';

const CATEGORIES: ProductCategory[] = ['FOOD', 'TOY', 'CLOTHES', 'ACCESSORY', 'MEDICINE', 'OTHER'];
const COVER_KEYS: string[] = [
  'shop_real_3',
  'shop_real_4',
  'shop_real_5',
  'shop_banner_real_1',
  'shop_banner_real_2',
  'pet_dog_real_1',
  'pet_dog_real_2',
  'pet_dog_real_3',
  'pet_dog_real_4',
  'pet_cat_real_1',
  'pet_cat_real_2',
  'pet_cat_real_3',
  'pet_cat_real_4'
];

interface Params {
  productId?: number;
}

function categoryLabel(category: ProductCategory): string {
  return category === 'FOOD'
    ? '主粮零食'
    : category === 'TOY'
      ? '玩具互动'
      : category === 'CLOTHES'
        ? '宠物服饰'
        : category === 'ACCESSORY'
          ? '护理用品'
          : category === 'MEDICINE'
            ? '健康护理'
            : '其他';
}

@Entry
@Component
struct NewProduct {
  @State private productId: number = 0;
  @State private name: string = '';
  @State private description: string = '';
  @State private price: string = '';
  @State private stockQuantity: string = '10';
  @State private category: ProductCategory = 'FOOD';
  @State private imageKey: string = COVER_KEYS[0];
  @State private imageUrlInput: string = '';
  @State private loading: boolean = false;
  @State private pageLoading: boolean = false;
  @State private errorText: string = '';

  aboutToAppear(): void {
    AppRouter.bind(this);
    const params = AppRouter.params<Params>(this);
    this.productId = Number(params?.productId ?? 0);
    if (this.productId > 0) {
      this.load();
    }
  }

  private isEditMode(): boolean {
    return this.productId > 0;
  }

  private async load(): Promise<void> {
    this.pageLoading = true;
    this.errorText = '';
    try {
      const product = await Api.getProduct(this.productId);
      this.name = product.name;
      this.description = product.description ?? '';
      this.price = product.price;
      this.stockQuantity = String(product.stockQuantity ?? 0);
      this.category = (product.category ?? 'FOOD') as ProductCategory;
      this.imageKey = product.image ?? COVER_KEYS[0];
      this.imageUrlInput = product.image ?? '';
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '加载商品失败';
    } finally {
      this.pageLoading = false;
    }
  }

  private async submit(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      AppRouter.replace('pages/Login', undefined, this);
      return;
    }
    if (user.role !== 'SELLER' && user.role !== 'ADMIN') {
      this.errorText = '只有卖家或管理员可以维护商品';
      return;
    }
    if (!this.name.trim() || !this.price.trim()) {
      this.errorText = '请填写商品名称和价格';
      return;
    }
    this.loading = true;
    this.errorText = '';
    const payload: Product = {
      id: this.isEditMode() ? this.productId : undefined,
      name: this.name.trim(),
      description: this.description.trim() || undefined,
      price: Number(this.price).toFixed(2),
      image: this.imageUrlInput.trim() || this.imageKey,
      stockQuantity: Math.max(0, Math.floor(Number(this.stockQuantity) || 0)),
      category: this.category
    };
    try {
      if (this.isEditMode()) {
        await Api.updateProduct(this.productId, payload);
        AppPrompt.toast('商品已更新', this);
      } else {
        await Api.createProduct(payload);
        AppPrompt.toast('商品已创建', this);
      }
      AppRouter.back(this);
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : this.isEditMode() ? '更新失败' : '创建失败';
    } finally {
      this.loading = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        TopBar({
          title: this.isEditMode() ? '编辑商品' : '上新商品',
          subtitle: this.isEditMode() ? '维护价格、库存、封面与分类。' : '卖家可在这里创建最小可用商品信息。',
          onBack: () => AppRouter.back(this)
        })

        if (this.pageLoading) {
          Row({ space: 8 }) {
            LoadingProgress().width(20).height(20).color(Theme.primary)
            Text('正在加载商品信息…')
              .fontSize(12)
              .fontColor(Theme.textMuted)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding(20)
        }

        if (!this.pageLoading) {
          Image(MediaAssets.productImage(this.imageKey, this.productId, this.category))
            .width('100%')
            .height(220)
            .borderRadius(24)
            .objectFit(ImageFit.Cover)

          SectionTitle({ title: '封面图' })
          Field({
            label: '图片链接',
            placeholder: '支持 https://... 或多个链接用逗号分隔',
            value: this.imageUrlInput,
            onChange: (value: string) => {
              this.imageUrlInput = value;
              this.imageKey = value.trim() || COVER_KEYS[0];
            }
          })
          Row({ space: 10 }) {
            ForEach(COVER_KEYS, (cover: string) => {
              Image(MediaAssets.productImage(cover, this.productId, this.category))
                .width(72)
                .height(72)
                .borderRadius(18)
                .border({ width: this.imageKey === cover ? 2 : 1, color: this.imageKey === cover ? Theme.primary : Theme.border })
                .onClick(() => {
                  this.imageKey = cover;
                  this.imageUrlInput = cover;
                })
            }, (cover: string) => cover)
          }

          SectionTitle({ title: '商品信息' })
          Field({ label: '商品名称', placeholder: '例如：冻干主食包', value: this.name, onChange: (value: string) => this.name = value })
          Column({ space: 6 }) {
            Text('商品描述')
              .fontSize(13)
              .fontColor(Theme.textSecondary)
            TextArea({ placeholder: '适用场景、规格、卖点说明', text: this.description })
              .height(120)
              .backgroundColor(Theme.surfaceMuted)
              .border({ width: 1, color: Theme.border })
              .borderRadius(12)
              .padding(12)
              .onChange((value: string) => this.description = value)
          }
          .width('100%')
          Field({ label: '价格', placeholder: '例如：69.90', value: this.price, onChange: (value: string) => this.price = value, type: InputType.Number })
          Field({ label: '库存', placeholder: '例如：20', value: this.stockQuantity, onChange: (value: string) => this.stockQuantity = value, type: InputType.Number })
          OptionGroup({
            label: '商品分类',
            options: CATEGORIES.map((item: ProductCategory) => categoryLabel(item)),
            selected: categoryLabel(this.category),
            onSelect: (value: string) => {
              const raw = CATEGORIES.find((item: ProductCategory) => categoryLabel(item) === value) ?? 'FOOD';
              this.category = raw;
            }
          })

          ErrorText({ text: this.errorText })
          PrimaryButton({ text: this.loading ? '提交中…' : this.isEditMode() ? '保存商品' : '创建商品', disabled: this.loading, action: () => this.submit() })
        }
      }
      .padding(16)
      .width('100%')
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }
}
