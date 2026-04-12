import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Product } from '../model/Models';
import { CartStore } from '../store/CartStore';
import { AppPrompt } from '../common/AppPrompt';
import { MediaAssets } from '../assets/MediaAssets';
import { priceLabel, productCategoryLabel, shortDate } from '../common/Formatters';
import { Theme } from '../common/Theme';
import { StickyBottomBar, TopBar } from '../components/Ui';

interface IdParams {
  id?: number;
}

@Entry
@Component
struct ProductDetail {
  @State private productId: number = 0;
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private product: Product | undefined = undefined;
  @State private qty: number = 1;
  @State private activeImageIndex: number = 0;

  aboutToAppear(): void {
    AppRouter.bind(this);
    const params = AppRouter.params<IdParams>(this);
    this.productId = Number(params?.id ?? 0);
    this.load();
  }

  private async load(): Promise<void> {
    if (!this.productId) {
      this.errorText = '无效商品';
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      this.product = await Api.getProduct(this.productId);
      const stock = Math.max(0, this.product.stockQuantity ?? 0);
      this.qty = stock > 0 ? Math.min(Math.max(1, this.qty), stock) : 1;
      this.activeImageIndex = 0;
    } catch (e) {
      this.product = undefined;
      this.errorText = e instanceof Error ? e.message : '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private gallery(): Array<Resource | string> {
    if (!this.product) {
      return [MediaAssets.placeholder()];
    }
    return MediaAssets.productGallery(this.product.image, this.product.id ?? 0, this.product.category);
  }

  private totalPriceText(): string {
    if (!this.product) {
      return '￥0.00';
    }
    const price = Number(priceLabel(this.product.price as number | string | object | undefined));
    return `￥${(Number.isFinite(price) ? price * this.qty : 0).toFixed(2)}`;
  }

  private async addToCart(goCart: boolean): Promise<void> {
    if (!this.productId || !this.product) {
      this.errorText = '商品信息不可用';
      return;
    }
    const stock = Math.max(0, this.product.stockQuantity ?? 0);
    if (stock <= 0) {
      this.errorText = '该商品暂时缺货';
      return;
    }
    try {
      const current = CartStore.getQuantity(this.productId);
      const next = Math.min(stock, current + this.qty);
      if (next <= current) {
        this.errorText = '已达到当前库存上限';
        return;
      }
      await CartStore.setQuantity(this.productId, next);
      this.errorText = '';
      if (goCart) {
        AppRouter.push('pages/Cart', undefined, this);
        return;
      }
      AppPrompt.toast('已加入购物车', this);
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '加入购物车失败';
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        TopBar({
          title: '商品详情',
          subtitle: '图集、库存、说明和购买动作统一在这里。',
          onBack: () => AppRouter.back(this),
          actionText: '购物车',
          onAction: () => AppRouter.push('pages/Cart', undefined, this)
        })

        Scroll() {
          Column({ space: 16 }) {
            if (this.errorText) {
              Text(this.errorText)
                .fontSize(13)
                .fontColor(Theme.danger)
                .width('100%')
            }

            if (this.product) {
              Image(this.gallery()[this.activeImageIndex])
                .width('100%')
                .height(280)
                .borderRadius(28)
                .objectFit(ImageFit.Cover)

              Row({ space: 10 }) {
                ForEach(this.gallery(), (image: Resource | string, index: number) => {
                  Image(image)
                    .width(74)
                    .height(74)
                    .borderRadius(18)
                    .objectFit(ImageFit.Cover)
                    .border({ width: this.activeImageIndex === index ? 2 : 0, color: Theme.primary })
                    .onClick(() => this.activeImageIndex = index)
                }, (_: Resource | string, index: number) => String(index))
              }
              .width('100%')

              Column({ space: 12 }) {
                Row({ space: 8 }) {
                  Text(this.product.name)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.textPrimary)
                    .layoutWeight(1)
                  Text(productCategoryLabel(this.product.category))
                    .fontSize(11)
                    .fontColor('#D97706')
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .backgroundColor(Theme.warmSoft)
                    .borderRadius(12)
                }

                Text(this.product.description ?? '暂无描述')
                  .fontSize(14)
                  .fontColor(Theme.textPrimary)
                  .lineHeight(22)

                Row({ space: 12 }) {
                  Text(`￥${priceLabel(this.product.price as number | string | object | undefined)}`)
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.accentPink)
                  Text((this.product.stockQuantity ?? 0) > 0 ? `库存 ${this.product.stockQuantity}` : '暂时缺货')
                    .fontSize(12)
                    .fontColor((this.product.stockQuantity ?? 0) > 0 ? Theme.textMuted : Theme.danger)
                  Text(`上架 ${shortDate(this.product.createdAt)}`)
                    .fontSize(12)
                    .fontColor(Theme.textMuted)
                }
              }
              .padding(18)
              .backgroundColor(Color.White)
              .borderRadius(24)

              Column({ space: 12 }) {
                Text('适用说明')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.textPrimary)
                Text('· 购买数量会与购物车已选数量一并校验，不会超过当前库存。')
                  .fontSize(13)
                  .fontColor(Theme.textSecondary)
                Text('· 商品图片与商城列表、购物车展示保持同一图片源。')
                  .fontSize(13)
                  .fontColor(Theme.textSecondary)
                Text('· 适合宠物日常喂养、护理或互动场景。')
                  .fontSize(13)
                  .fontColor(Theme.textSecondary)
              }
              .padding(18)
              .backgroundColor(Color.White)
              .borderRadius(24)

              Column({ space: 12 }) {
                Text('购买数量')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.textPrimary)
                Row({ space: 12 }) {
                  Button('-')
                    .height(38)
                    .width(42)
                    .borderRadius(12)
                    .backgroundColor('#F3F6FB')
                    .fontColor(Theme.textSecondary)
                    .enabled((this.product?.stockQuantity ?? 0) > 0)
                    .onClick(() => this.qty = Math.max(1, this.qty - 1))
                  Text(String(this.qty))
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                  Button('+')
                    .height(38)
                    .width(42)
                    .borderRadius(12)
                    .backgroundColor('#F3F6FB')
                    .fontColor(Theme.textSecondary)
                    .enabled((this.product?.stockQuantity ?? 0) > 0)
                    .onClick(() => this.qty = Math.min(Math.max(1, this.product?.stockQuantity ?? 1), this.qty + 1))
                }
                .width('100%')
              }
              .padding(18)
              .backgroundColor(Color.White)
              .borderRadius(24)
            } else if (this.loading) {
              Column({ space: 10 }) {
                LoadingProgress()
                  .width(24)
                  .height(24)
                  .color(Theme.primary)
                Text('正在加载商品详情…')
                  .fontSize(13)
                  .fontColor(Theme.textMuted)
              }
              .width('100%')
              .padding(30)
              .alignItems(HorizontalAlign.Center)
            }

            Blank().height(this.product ? 96 : 24)
          }
          .padding(16)
          .width('100%')
        }
        .layoutWeight(1)
      }
      .height('100%')
      .width('100%')
      .backgroundColor(Theme.background)

      if (this.product) {
        StickyBottomBar({
          title: '结算金额',
          valueText: this.totalPriceText(),
          secondaryText: (this.product.stockQuantity ?? 0) > 0 ? '加入购物车' : '',
          primaryText: (this.product.stockQuantity ?? 0) > 0 ? '去结算' : '暂时缺货',
          disabled: (this.product.stockQuantity ?? 0) <= 0,
          onSecondary: () => this.addToCart(false),
          onPrimary: () => this.addToCart(true)
        })
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }
}
