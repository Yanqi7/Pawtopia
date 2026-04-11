import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Product, ProductCategory, UserRole } from '../model/Models';
import { CartSnapshot, CartStore } from '../store/CartStore';
import { AppStatus } from '../app/AppStatus';
import { EmptyState, OfflineBanner, SectionHeader } from '../components/Ui';
import { MediaAssets } from '../assets/MediaAssets';
import { normalizeKeyword, productCategoryLabel, priceLabel } from '../common/Formatters';
import { Theme } from '../common/Theme';
import { SessionStore } from '../store/SessionStore';

interface ProductDetailParams {
  id?: number;
}

interface CategoryOption {
  label: string;
  value: ProductCategory | 'ALL';
}

type MallView = 'ALL' | 'MINE';

@Component
export struct MallTab {
  initialView: MallView = 'ALL';
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private allProducts: Product[] = [];
  @State private visibleList: Product[] = [];
  @State private keyword: string = '';
  @State private cartCount: number = 0;
  @State private selectedCategory: ProductCategory | 'ALL' = 'ALL';
  @State private viewMode: MallView = 'ALL';
  @State private searchInput: string = '';

  private readonly categories: CategoryOption[] = [
    { label: '全部', value: 'ALL' },
    { label: '主粮零食', value: 'FOOD' },
    { label: '玩具互动', value: 'TOY' },
    { label: '宠物服饰', value: 'CLOTHES' },
    { label: '护理用品', value: 'ACCESSORY' },
    { label: '健康护理', value: 'MEDICINE' }
  ];

  private readonly cartListener = (snapshot: CartSnapshot): void => {
    this.cartCount = snapshot.count;
  };

  aboutToAppear(): void {
    AppRouter.bind(this);
    const viewChanged = this.viewMode !== this.initialView;
    if (viewChanged) {
      this.viewMode = this.initialView;
      this.keyword = '';
      this.searchInput = '';
      this.selectedCategory = 'ALL';
      this.allProducts = [];
    }
    this.cartCount = CartStore.getTotalCount();
    CartStore.subscribe(this.cartListener);
    this.refresh();
  }

  aboutToDisappear(): void {
    CartStore.unsubscribe(this.cartListener);
  }

  private role(): UserRole {
    return (SessionStore.getUser()?.role ?? 'USER') as UserRole;
  }

  private async refresh(): Promise<void> {
    this.loading = true;
    this.errorText = '';
    try {
      const user = SessionStore.getUser();
      if (this.viewMode === 'MINE' && user?.id && this.role() === 'SELLER') {
        const page = await Api.getProductsBySeller(user.id, 0, 40);
        this.allProducts = page.content;
      } else if (this.keyword.trim()) {
        const page = await Api.searchProducts(this.keyword.trim(), 0, 40);
        this.allProducts = page.content;
      } else {
        const page = await Api.getProducts(0, 40);
        this.allProducts = page.content;
      }
      this.cartCount = CartStore.getTotalCount();
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '加载失败';
    } finally {
      this.loading = false;
    }
    this.applyFilter();
  }

  private applyFilter(): void {
    const kw = normalizeKeyword(this.keyword);
    this.visibleList = this.allProducts.filter((product: Product) => {
      const matchKw = !kw || normalizeKeyword(`${product.name} ${product.description ?? ''}`).indexOf(kw) >= 0;
      const matchCat = this.selectedCategory === 'ALL' || product.category === this.selectedCategory;
      return matchKw && matchCat;
    });
  }

  private priceText(product: Product): string {
    return priceLabel(product.price as number | string | object | undefined);
  }

  private async addToCart(product: Product): Promise<void> {
    if (!product.id) {
      return;
    }
    if ((product.stockQuantity ?? 0) <= 0) {
      this.errorText = '该商品暂时缺货';
      return;
    }
    try {
      const next = CartStore.getQuantity(product.id) + 1;
      const stock = Math.max(0, product.stockQuantity ?? 0);
      await CartStore.setQuantity(product.id, Math.min(stock, next));
      this.cartCount = CartStore.getTotalCount();
      this.errorText = '';
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '加入购物车失败';
    }
  }

  build() {
    Column() {
      // ── 顶部搜索栏（固定，淘宝风格）──
      Column({ space: 0 }) {
        Row({ space: 10 }) {
          // 搜索框
          Row({ space: 8 }) {
            Image($r('app.media.hero_search'))
              .width(16).height(16).fillColor(Theme.textMuted)
            TextInput({ placeholder: '搜索宠物用品…', text: this.searchInput })
              .layoutWeight(1).height(36).backgroundColor('transparent')
              .border({ width: 0 }).fontSize(13).fontColor(Theme.textPrimary)
              .onChange((v: string) => this.searchInput = v)
              .onSubmit(() => {
                this.keyword = this.searchInput;
                this.viewMode = 'ALL';
                this.refresh();
              })
          }
          .layoutWeight(1).height(36)
          .padding({ left: 10, right: 10 })
          .backgroundColor('#F5F5F5').borderRadius(18)

          // 购物车图标（可点击）
          Stack({ alignContent: Alignment.TopEnd }) {
            Image($r('app.media.gouwuche'))
              .width(24).height(24).fillColor(Theme.textPrimary)
            if (this.cartCount > 0) {
              Text(this.cartCount > 99 ? '99+' : String(this.cartCount))
                .fontSize(9).fontColor(Color.White)
                .padding({ left: 3, right: 3, top: 1, bottom: 1 })
                .backgroundColor('#E4393C').borderRadius(8)
                .position({ top: -6, right: -8 })
            }
          }
          .width(36).height(36)
          .onClick(() => AppRouter.push('pages/Cart', undefined, this))

          if (this.role() === 'SELLER') {
            Text('上新')
              .fontSize(13).fontColor(Theme.primary).fontWeight(FontWeight.Medium)
              .onClick(() => AppRouter.push('pages/NewProduct', undefined, this))
          }
        }
        .width('100%').padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor(Color.White)

        // 分类横滑
        Scroll() {
          Row({ space: 0 }) {
            ForEach(this.categories, (cat: CategoryOption) => {
              Column({ space: 4 }) {
                Text(cat.label)
                  .fontSize(13)
                  .fontColor(this.selectedCategory === cat.value ? Theme.primary : Theme.textPrimary)
                  .fontWeight(this.selectedCategory === cat.value ? FontWeight.Bold : FontWeight.Normal)
                Column()
                  .width(this.selectedCategory === cat.value ? 20 : 0)
                  .height(2)
                  .backgroundColor(Theme.primary)
                  .borderRadius(1)
              }
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .onClick(() => {
                this.selectedCategory = cat.value;
                this.applyFilter();
              })
            }, (cat: CategoryOption) => cat.value)
          }
        }
        .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
        .backgroundColor(Color.White)
        .border({ width: 0, color: 'transparent' })

        Divider().color('#F0F0F0').strokeWidth(1)
      }

      // ── 商品列表区 ──
      Scroll() {
        Column({ space: 0 }) {
          if (!AppStatus.isBackendOnline()) {
            OfflineBanner({ text: '当前无法连接服务，商品与库存信息暂不可用', action: () => this.refresh() })
              .margin({ left: 12, right: 12, top: 8 })
          }

          if (this.errorText) {
            Text(this.errorText)
              .fontSize(12).fontColor(Theme.danger)
              .padding({ left: 12, right: 12, top: 6 }).width('100%')
          }

          // 卖家视图切换
          if (this.role() === 'SELLER') {
            Row({ space: 8 }) {
              Text(this.viewMode === 'ALL' ? '全部商品' : '我的商品')
                .fontSize(13).fontColor(Theme.textSecondary)
              Text(this.viewMode === 'ALL' ? '切换到我的商品' : '切换到全部商品')
                .fontSize(12).fontColor(Theme.primary)
                .onClick(() => {
                  this.viewMode = this.viewMode === 'ALL' ? 'MINE' : 'ALL';
                  this.refresh();
                })
              Blank()
              Text('订单管理')
                .fontSize(12).fontColor(Theme.primary)
                .onClick(() => AppRouter.push('pages/Orders', undefined, this))
            }
            .padding({ left: 12, right: 12, top: 10, bottom: 6 }).width('100%')
          }

          // 商品列表标题
          Row() {
            Text(this.viewMode === 'MINE' ? '我的商品' : '精选好物')
              .fontSize(15).fontWeight(FontWeight.Bold).fontColor(Theme.textPrimary)
            Blank()
            if (this.loading) {
              LoadingProgress().width(16).height(16).color(Theme.primary)
            } else {
              Text('刷新')
                .fontSize(12).fontColor(Theme.primary)
                .onClick(() => this.refresh())
            }
          }
          .padding({ left: 12, right: 12, top: 12, bottom: 8 }).width('100%')

          if (!this.loading && this.visibleList.length === 0) {
            EmptyState({
              title: '没有找到匹配商品',
              description: '试试切换分类或搜索其他关键字。',
              actionText: '清空筛选',
              action: () => {
                this.keyword = '';
                this.searchInput = '';
                this.selectedCategory = 'ALL';
                this.viewMode = 'ALL';
                this.refresh();
              }
            })
          } else {
            // 两列瀑布流（淘宝风格）
            this.ProductGrid()
          }

          Blank().height(24)
        }
        .width('100%')
      }
      .layoutWeight(1).backgroundColor('#F5F5F5')
    }
    .height('100%').width('100%').backgroundColor('#F5F5F5')
  }

  @Builder private ProductGrid() {
    Column({ space: 8 }) {
      // 每两个商品一行
      ForEach(this.buildRows(), (row: Product[], rowIdx: number) => {
        Row({ space: 8 }) {
          ForEach(row, (product: Product) => {
            this.ProductCard(product)
          }, (product: Product) => String(product.id))
          if (row.length === 1) {
            Column().layoutWeight(1)
          }
        }
        .padding({ left: 8, right: 8 })
        .width('100%')
      }, (_: Product[], rowIdx: number) => String(rowIdx))
    }
    .padding({ top: 4 })
    .width('100%')
  }

  private buildRows(): Product[][] {
    const products = this.visibleList;
    const rows: Product[][] = [];
    for (let i = 0; i < products.length; i += 2) {
      const row: Product[] = [products[i]];
      if (i + 1 < products.length) {
        row.push(products[i + 1]);
      }
      rows.push(row);
    }
    return rows;
  }

  @Builder private ProductCard(product: Product) {
    Column({ space: 8 }) {
      // 商品图
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(MediaAssets.productImage(product.image, product.id ?? 0, product.category))
          .width('100%').aspectRatio(1).borderRadius(8).objectFit(ImageFit.Cover)
        if ((product.stockQuantity ?? 0) <= 0) {
          Text('已售罄')
            .fontSize(10).fontColor(Color.White)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor('#00000066').borderRadius(4)
            .margin(6)
        }
      }
      .width('100%')

      Column({ space: 4 }) {
        Text(product.name)
          .fontSize(13).fontColor(Theme.textPrimary)
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(productCategoryLabel(product.category))
          .fontSize(10).fontColor(Theme.textMuted)
        Row({ space: 4 }) {
          Text('￥')
            .fontSize(11).fontColor('#E4393C').fontWeight(FontWeight.Bold)
          Text(this.priceText(product))
            .fontSize(18).fontColor('#E4393C').fontWeight(FontWeight.Bold)
          Blank()
          if ((product.stockQuantity ?? 0) > 0) {
            Text('＋')
              .width(26).height(26).textAlign(TextAlign.Center)
              .fontSize(18).fontColor(Color.White)
              .backgroundColor('#E4393C').borderRadius(13)
              .onClick(() => this.addToCart(product))
          }
        }
        .width('100%').alignItems(VerticalAlign.Bottom)
      }
      .padding({ left: 8, right: 8, bottom: 10 })
      .width('100%')
    }
    .layoutWeight(1)
    .backgroundColor(Color.White).borderRadius(10)
    .clip(true)
    .onClick(() => AppRouter.push('pages/ProductDetail', { id: product.id } as ProductDetailParams, this))
  }
}
