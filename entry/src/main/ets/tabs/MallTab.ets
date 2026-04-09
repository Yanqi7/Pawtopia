import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Product, ProductCategory } from '../model/Models';
import { CartStore } from '../store/CartStore';
import { AppStatus } from '../app/AppStatus';
import { EmptyState, OfflineBanner } from '../components/Ui';
import { MediaAssets } from '../assets/MediaAssets';
import { Theme } from '../common/Theme';
import { normalizeKeyword, productCategoryLabel } from '../common/Formatters';

interface ProductDetailParams {
  id?: number;
}

interface CategoryOption {
  label: string;
  value: ProductCategory | 'ALL';
}

@Component
export struct MallTab {
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private allProducts: Product[] = [];
  @State private keyword: string = '';
  @State private cartCount: number = 0;
  @State private selectedCategory: ProductCategory | 'ALL' = 'ALL';

  private readonly categories: CategoryOption[] = [
    { label: '全部', value: 'ALL' },
    { label: '主粮零食', value: 'FOOD' },
    { label: '玩具互动', value: 'TOY' },
    { label: '护理用品', value: 'ACCESSORY' },
    { label: '健康护理', value: 'MEDICINE' }
  ];

  aboutToAppear(): void {
    this.cartCount = CartStore.getTotalCount();
    this.refresh();
  }

  private async refresh(): Promise<void> {
    this.loading = true;
    this.errorText = '';
    try {
      const page = this.keyword.trim() ? await Api.searchProducts(this.keyword.trim(), 0, 40) : await Api.getProducts(0, 40);
      this.allProducts = page.content;
      this.cartCount = CartStore.getTotalCount();
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private visibleProducts(): Product[] {
    const keyword = normalizeKeyword(this.keyword);
    return this.allProducts.filter((product: Product) => {
      const matchKeyword = !keyword || normalizeKeyword(`${product.name} ${product.description ?? ''}`).indexOf(keyword) >= 0;
      const matchCategory = this.selectedCategory === 'ALL' || product.category === this.selectedCategory;
      return matchKeyword && matchCategory;
    });
  }

  private async addToCart(product: Product): Promise<void> {
    if (!product.id) {
      return;
    }
    await CartStore.add(product.id, 1);
    this.cartCount = CartStore.getTotalCount();
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomStart }) {
        Image(MediaAssets.mallHero())
          .width('100%')
          .height(176)
          .objectFit(ImageFit.Cover)
        Column()
          .width('100%')
          .height(176)
          .linearGradient({ angle: 180, colors: [['#0F172A10', 0], ['#0F172A55', 0.48], ['#F3F7FF', 1]] })

        Column({ space: 12 }) {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text('宠物商城')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text('按名称匹配更合适的商品图')
                .fontSize(11)
                .fontColor('#F8FAFC')
            }
            .layoutWeight(1)
            Stack() {
              Button()
                .width(42)
                .height(42)
                .borderRadius(21)
                .backgroundColor('#FFFFFFF0')
                .onClick(() => AppRouter.push('pages/Cart'))
              Image($r('app.media.gouwuche'))
                .width(18)
                .height(18)
                .fillColor(Theme.primary)
              if (this.cartCount > 0) {
                Text(String(this.cartCount))
                  .fontSize(10)
                  .fontColor(Color.White)
                  .backgroundColor('#FF5A5F')
                  .borderRadius(10)
                  .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                  .position({ top: -6, right: -6 })
              }
            }
          }
          .width('100%')

          Row({ space: 8 }) {
            Image($r('app.media.hero_search'))
              .width(18)
              .height(18)
            TextInput({ placeholder: '搜索冻干、护理、喂食器…', text: this.keyword })
              .layoutWeight(1)
              .height(40)
              .backgroundColor('transparent')
              .border({ width: 0 })
              .fontSize(14)
              .onChange((value: string) => this.keyword = value)
            Button('搜索')
              .height(30)
              .backgroundColor(Theme.primary)
              .fontColor(Color.White)
              .borderRadius(15)
              .fontSize(12)
              .onClick(() => this.refresh())
          }
          .width('100%')
          .height(42)
          .padding({ left: 12, right: 8 })
          .backgroundColor('#FFFFFFF0')
          .borderRadius(21)
        }
        .padding({ left: 16, right: 16, bottom: 12 })
        .width('100%')
      }

      Scroll() {
        Row({ space: 8 }) {
          ForEach(this.categories, (category: CategoryOption) => {
            Text(category.label)
              .fontSize(12)
              .fontColor(this.selectedCategory === category.value ? Color.White : Theme.textSecondary)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor(this.selectedCategory === category.value ? Theme.primary : Color.White)
              .borderRadius(16)
              .onClick(() => this.selectedCategory = category.value)
          }, (category: CategoryOption) => category.value)
        }
        .padding({ left: 16, right: 16, top: 10, bottom: 8 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      if (!AppStatus.isBackendOnline()) {
        OfflineBanner({ text: '当前为本地商品库，仍可浏览和下单', action: () => this.refresh() })
          .padding({ left: 16, right: 16, bottom: 8 })
      }

      if (this.errorText) {
        Text(this.errorText)
          .fontSize(13)
          .fontColor(Color.Red)
          .padding({ left: 16, right: 16, bottom: 8 })
      }

      if (!this.loading && this.visibleProducts().length === 0) {
        EmptyState({
          title: '没有找到匹配商品',
          description: '试试切换分类或搜索其他关键字。',
          actionText: '清空筛选',
          action: () => {
            this.keyword = '';
            this.selectedCategory = 'ALL';
            this.refresh();
          }
        })
      } else {
        List() {
          ForEach(this.visibleProducts(), (product: Product) => {
            ListItem() {
              Row({ space: 12 }) {
                Image(MediaAssets.productImage(product.name, product.id ?? 0, product.category))
                  .width(108)
                  .height(108)
                  .borderRadius(22)
                  .objectFit(ImageFit.Cover)
                Column({ space: 8 }) {
                  Row({ space: 8 }) {
                    Text(product.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Theme.textPrimary)
                      .layoutWeight(1)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(productCategoryLabel(product.category))
                      .fontSize(10)
                      .fontColor('#FF8A3D')
                      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                      .backgroundColor('#FFF3E0')
                      .borderRadius(10)
                  }
                  .width('100%')

                  Text(product.description ?? '')
                    .fontSize(12)
                    .fontColor(Theme.textSecondary)
                    .lineHeight(18)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Row({ space: 10 }) {
                    Text(`￥${product.price}`)
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FF5A5F')
                    Text(`库存 ${product.stockQuantity}`)
                      .fontSize(11)
                      .fontColor(Theme.textMuted)
                  }

                  Row({ space: 10 }) {
                    Button('加购')
                      .height(32)
                      .padding({ left: 14, right: 14 })
                      .backgroundColor('#E8F1FF')
                      .fontColor(Theme.primary)
                      .borderRadius(16)
                      .fontSize(12)
                      .onClick(() => this.addToCart(product))
                    Button('查看详情')
                      .height(32)
                      .padding({ left: 14, right: 14 })
                      .backgroundColor(Theme.primary)
                      .fontColor(Color.White)
                      .borderRadius(16)
                      .fontSize(12)
                      .onClick(() => AppRouter.push('pages/ProductDetail', { id: product.id } as ProductDetailParams))
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(24)
            }
            .padding({ left: 16, right: 16, bottom: 12 })
            .onClick(() => AppRouter.push('pages/ProductDetail', { id: product.id } as ProductDetailParams))
          }, (product: Product) => String(product.id))

          ListItem() {
            if (this.loading) {
              Row({ space: 8 }) {
                LoadingProgress().width(20).height(20).color(Theme.primary)
                Text('正在刷新商品…').fontSize(12).fontColor(Theme.textMuted)
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding(16)
            }
          }
        }
        .layoutWeight(1)
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }
}
