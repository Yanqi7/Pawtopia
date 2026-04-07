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
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
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
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column({ space: 16 }) {
          if (this.errorText) {
            Text(this.errorText)
              .fontSize(13)
              .fontColor(Color.Red)
              .padding(16)
          }

          if (this.product) {
            Image(MediaAssets.productImage(this.product.image, this.product.id ?? 0, this.product.category))
              .width('100%')
              .height(260)
              .borderRadius(18)
              .objectFit(ImageFit.Cover)

            Column({ space: 12 }) {
              Row({ space: 8 }) {
                Text(this.product.name)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
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
                .fontColor('#333')
                .lineHeight(22)
              Row({ space: 10 }) {
                Text(`￥${this.product.price}`)
                  .fontSize(24)
                  .fontColor(Color.Red)
                  .fontWeight(FontWeight.Bold)
                Text(`库存：${this.product.stockQuantity}`)
                  .fontSize(12)
                  .fontColor('#999')
                Text(`上架：${shortDate(this.product.createdAt)}`)
                  .fontSize(12)
                  .fontColor('#999')
              }
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)

            Column({ space: 12 }) {
              Text('购买数量')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
              Row({ space: 12 }) {
                Button('-')
                  .height(36)
                  .width(40)
                  .borderRadius(8)
                  .backgroundColor('#F0F2F5')
                  .onClick(() => this.qty = Math.max(1, this.qty - 1))
                Text(String(this.qty))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
                Button('+')
                  .height(36)
                  .width(40)
                  .borderRadius(8)
                  .backgroundColor('#F0F2F5')
                  .onClick(() => this.qty = Math.min(Math.max(1, this.product?.stockQuantity ?? 1), this.qty + 1))
              }
              .width('100%')
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
          } else if (this.loading) {
            Text('��载中…')
              .fontSize(14)
              .fontColor('#999')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(40)
          }

          Blank().height(16)
        }
        .padding(16)
      }
      .layoutWeight(1)

      if (this.product) {
        Row({ space: 12 }) {
          Button('加入购物车')
            .height(44)
            .layoutWeight(1)
            .backgroundColor('#E8F1FF')
            .fontColor(Theme.primary)
            .borderRadius(12)
            .fontSize(14)
            .onClick(() => this.addToCart(false))

          Button('去结算')
            .height(44)
            .layoutWeight(1)
            .backgroundColor(Theme.primary)
            .fontColor(Color.White)
            .borderRadius(12)
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
    .backgroundColor('#F5F5F5')
  }
}
