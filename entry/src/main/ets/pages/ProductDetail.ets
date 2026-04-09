import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Product } from '../model/Models';
import { CartStore } from '../store/CartStore';
import { AppPrompt } from '../common/AppPrompt';
import { MediaAssets } from '../assets/MediaAssets';
import { productCategoryLabel, shortDate } from '../common/Formatters';
import { Theme } from '../common/Theme';

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
    const params = AppRouter.params<IdParams>();
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
      this.activeImageIndex = 0;
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private gallery(): Resource[] {
    if (!this.product) {
      return [];
    }
    return MediaAssets.productGallery(this.product.image, this.product.id ?? 0, this.product.category);
  }

  private async addToCart(goCart: boolean): Promise<void> {
    if (!this.productId || !this.product) {
      return;
    }
    await CartStore.add(this.productId, this.qty);
    if (goCart) {
      AppRouter.push('pages/Cart');
      return;
    }
    AppPrompt.toast('已加入购物车');
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Image($r('app.media.hero_back'))
          .width(24)
          .height(24)
          .onClick(() => AppRouter.back())
        Blank()
        Text('商品详情')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Blank()
        Image($r('app.media.gouwuche'))
          .width(24)
          .height(24)
          .fillColor(Theme.primary)
          .onClick(() => AppRouter.push('pages/Cart'))
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .width('100%')
      .backgroundColor(Color.White)

      Scroll() {
        Column({ space: 16 }) {
          if (this.errorText) {
            Text(this.errorText)
              .fontSize(13)
              .fontColor('#D14343')
              .padding(16)
          }

          if (this.product) {
            Image(this.gallery()[this.activeImageIndex])
              .width('100%')
              .height(280)
              .borderRadius(28)
              .objectFit(ImageFit.Cover)

            Row({ space: 10 }) {
              ForEach(this.gallery(), (image: Resource, index: number) => {
                Image(image)
                  .width(74)
                  .height(74)
                  .borderRadius(18)
                  .objectFit(ImageFit.Cover)
                  .border({ width: this.activeImageIndex === index ? 2 : 0, color: Theme.primary })
                  .onClick(() => this.activeImageIndex = index)
              }, (_: Resource, index: number) => String(index))
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
                  .fontColor('#FF8A3D')
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor('#FFF1E8')
                  .borderRadius(12)
              }

              Text(this.product.description ?? '暂无描述')
                .fontSize(14)
                .fontColor(Theme.textPrimary)
                .lineHeight(22)

              Row({ space: 12 }) {
                Text(`￥${this.product.price}`)
                  .fontSize(26)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FF5A5F')
                Text(`库存 ${this.product.stockQuantity}`)
                  .fontSize(12)
                  .fontColor(Theme.textMuted)
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
              Text('· 购买数量与库存联动，结算时以后端校验为准。')
                .fontSize(13)
                .fontColor(Theme.textSecondary)
              Text('· 商品图片以商家上传或平台维护的图片字段为准。')
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

          Blank().height(16)
        }
        .padding(16)
      }
      .layoutWeight(1)

      if (this.product) {
        Row({ space: 12 }) {
          Button('加入购物车')
            .height(46)
            .layoutWeight(1)
            .backgroundColor('#E8F1FF')
            .fontColor(Theme.primary)
            .borderRadius(18)
            .fontSize(14)
            .onClick(() => this.addToCart(false))

          Button('去结算')
            .height(46)
            .layoutWeight(1)
            .backgroundColor(Theme.primary)
            .fontColor(Color.White)
            .borderRadius(18)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .onClick(() => this.addToCart(true))
        }
        .padding(16)
        .backgroundColor(Color.White)
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }
}
