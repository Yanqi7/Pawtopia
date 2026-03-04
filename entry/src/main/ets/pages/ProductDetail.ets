import router from '@ohos.router';
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
    const params = router.getParams() as IdParams;
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
    router.pushUrl({ url: 'pages/Cart' });
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Row() {
          Text('商品详情').fontSize(18).fontWeight(FontWeight.Bold)
          Blank()
          Text('返回').fontSize(14).fontColor('#2B7FFF').onClick(() => router.back())
        }

        if (this.errorText) {
          ErrorText({ text: this.errorText })
        }

        if (this.product) {
          Column({ space: 10 }) {
            Text(this.product!.name).fontSize(20).fontWeight(FontWeight.Bold)
            Text(`￥${this.product!.price}`).fontSize(18).fontColor('#2B7FFF').fontWeight(FontWeight.Bold)
            Text(this.product!.description ?? '暂无描述').fontSize(14).fontColor('#333')
            Text(`分类：${this.product!.category}  库存：${this.product!.stockQuantity}`).fontSize(12).fontColor('#999')
          }
          .padding(12)
          .backgroundColor('#F6F7F9')
          .borderRadius(12)

          SectionTitle({ title: '购买数量' })
          Row({ space: 10 }) {
            Button('-')
              .height(36)
              .width(44)
              .borderRadius(10)
              .backgroundColor('#F0F2F5')
              .onClick(() => this.qty = Math.max(1, this.qty - 1))
            Text(String(this.qty)).fontSize(16).width(60).textAlign(TextAlign.Center)
            Button('+')
              .height(36)
              .width(44)
              .borderRadius(10)
              .backgroundColor('#F0F2F5')
              .onClick(() => this.qty = Math.min(99, this.qty + 1))
          }
          PrimaryButton({ text: '加入购物车', disabled: false, action: () => this.addToCart() })
        } else if (this.loading) {
          Text('加载中…').fontSize(13).fontColor('#666')
        }
      }
      .padding(16)
      .width('100%')
    }
    .height('100%')
    .width('100%')
  }
}
