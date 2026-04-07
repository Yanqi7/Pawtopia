import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Product } from '../model/Models';
import { CartStore } from '../store/CartStore';
import { PrimaryButton, ErrorText, SectionTitle } from '../components/Ui';

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

  private async addToCart(): Promise<void> {
    if (!this.productId) {
      return;
    }
    await CartStore.add(this.productId, this.qty);
    AppRouter.push('pages/Cart');
  }

  build() {
    Column() {
      // 顶部导航
      Row({ space: 12 }) {
        Image($r('app.media.more'))
          .width(24)
          .height(24)
          .fillColor('#2B7FFF')
          .onClick(() => AppRouter.back())
        Blank()
        Text('商品详情')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
        Blank()
        Image($r('app.media.gouwuche'))
          .width(24)
          .height(24)
          .fillColor('#2B7FFF')
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .width('100%')
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: '#F0F0F0' })

      Scroll() {
        Column({ space: 16 }) {
          if (this.errorText) {
            Text(this.errorText)
              .fontSize(13)
              .fontColor(Color.Red)
              .padding(16)
          }

          if (this.product) {
            // 产品图片
            Image($r('app.media.dog'))
              .width('100%')
              .height(240)
              .borderRadius(12)
              .objectFit(ImageFit.Cover)

            // 产品信息
            Column({ space: 12 }) {
              // 标题和新品标签
              Row() {
                Text(this.product!.name)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
                Text('新')
                  .fontSize(10)
                  .fontColor(Color.White)
                  .backgroundColor(Color.Red)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .borderRadius(2)
              }
              .width('100%')

              // 价格
              Row({ space: 8 }) {
                Text(`￥${this.product!.price}`)
                  .fontSize(24)
                  .fontColor(Color.Red)
                  .fontWeight(FontWeight.Bold)
                Text(`库存：${this.product!.stockQuantity}件`)
                  .fontSize(12)
                  .fontColor('#999')
              }
              .width('100%')

              // 描述
              Text(this.product!.description ?? '暂无描述')
                .fontSize(14)
                .fontColor('#333')
                .width('100%')
                .lineHeight(1.6)

              // 评分
              Row({ space: 8 }) {
                Text('⭐ ' + Math.floor(Math.random() * 20 + 80) / 10)
                  .fontSize(12)
                  .fontWeight(FontWeight.Bold)
                Text('(已有 ' + Math.floor(Math.random() * 900 + 100) + ' 人购买)')
                  .fontSize(12)
                  .fontColor('#999')
              }
              .width('100%')
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)

            // 购买数量
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
                  .fontColor('#666')
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
                  .fontColor('#666')
                  .onClick(() => this.qty = Math.min(99, this.qty + 1))
              }
              .width('100%')
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)

            // 产品详情
            Column({ space: 12 }) {
              Text('产品详情')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)

              Column({ space: 8 }) {
                Row() {
                  Text('分类')
                    .fontSize(13)
                    .fontColor('#666')
                    .width(60)
                  Text(this.product!.category)
                    .fontSize(13)
                    .fontColor('#333')
                    .layoutWeight(1)
                }

                Row() {
                  Text('库存')
                    .fontSize(13)
                    .fontColor('#666')
                    .width(60)
                  Text(`${this.product!.stockQuantity} 件`)
                    .fontSize(13)
                    .fontColor('#333')
                    .layoutWeight(1)
                }
              }
              .width('100%')
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
          } else if (this.loading) {
            Text('加载中…')
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

      // 底部操作栏
      if (this.product) {
        Row({ space: 12 }) {
          Button('加入购物车')
            .height(44)
            .layoutWeight(1)
            .backgroundColor('#2B7FFF')
            .fontColor(Color.White)
            .borderRadius(8)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .onClick(() => this.addToCart())

          Button('立即购买')
            .height(44)
            .layoutWeight(1)
            .linearGradient({
              angle: 90,
              colors: [['#FF9D4E', 0.0], ['#FFB347', 1.0]]
            })
            .fontColor(Color.White)
            .borderRadius(8)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .onClick(() => this.addToCart())
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
