import router from '@ohos.router';
import { Api } from '../api/Api';
import { Product } from '../model/Models';
import { CartStore, CartItem } from '../store/CartStore';
import { SessionStore } from '../store/SessionStore';
import { PrimaryButton, ErrorText, Field, SectionTitle } from '../components/Ui';

interface CartLine {
  item: CartItem;
  product?: Product;
}

@Entry
@Component
struct Cart {
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private lines: CartLine[] = [];
  @State private address: string = '';
  @State private contactName: string = '';
  @State private contactPhone: string = '';
  @State private submitting: boolean = false;

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    this.loading = true;
    this.errorText = '';
    try {
      const items = CartStore.list();
      const products = await Promise.all(items.map((it) => Api.getProduct(it.productId).catch(() => undefined)));
      this.lines = items.map((item, i) => {
        const line: CartLine = { item: item, product: products[i] };
        return line;
      });
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private totalAmount(): number {
    return this.lines.reduce((sum, line) => {
      if (!line.product) {
        return sum;
      }
      const price = Number(line.product.price);
      if (Number.isNaN(price)) {
        return sum;
      }
      return sum + price * line.item.quantity;
    }, 0);
  }

  private async submitOrder(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      router.replaceUrl({ url: 'pages/Login' });
      return;
    }
    const userId = user.id;
    if (this.lines.length === 0) {
      this.errorText = '购物车为空';
      return;
    }
    if (!this.address.trim() || !this.contactName.trim() || !this.contactPhone.trim()) {
      this.errorText = '请填写收货信息';
      return;
    }
    const productIds: string[] = [];
    const quantities: string[] = [];
    this.lines.forEach((l) => {
      productIds.push(String(l.item.productId));
      quantities.push(String(l.item.quantity));
    });
    this.submitting = true;
    this.errorText = '';
    try {
      await Api.createOrder({
        userId: userId,
        productIds: productIds.join(','),
        quantities: quantities.join(','),
        totalAmount: String(this.totalAmount().toFixed(2)),
        status: 'PENDING',
        shippingAddress: this.address.trim(),
        contactName: this.contactName.trim(),
        contactPhone: this.contactPhone.trim()
      });
      await CartStore.clear();
      router.replaceUrl({ url: 'pages/Orders' });
    } catch (e) {
      this.errorText = (e as Error).message || '下单失败';
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Row() {
          Text('购物车').fontSize(18).fontWeight(FontWeight.Bold)
          Blank()
          Text('返回').fontSize(14).fontColor('#2B7FFF').onClick(() => router.back())
        }

        if (this.errorText) {
          ErrorText({ text: this.errorText })
        }

        SectionTitle({ title: '商品' })
        ForEach(this.lines, (line: CartLine) => {
          Row({ space: 10 }) {
            Column({ space: 4 }) {
              Text(line.product?.name ?? `商品 #${line.item.productId}`).fontSize(14).fontWeight(FontWeight.Medium)
              Text(`￥${line.product?.price ?? '-'}  x ${line.item.quantity}`).fontSize(12).fontColor('#666')
            }.layoutWeight(1)
            Button('-')
              .height(32)
              .width(40)
              .borderRadius(10)
              .backgroundColor('#F0F2F5')
              .onClick(async () => {
                await CartStore.add(line.item.productId, -1);
                this.reload();
              })
            Button('+')
              .height(32)
              .width(40)
              .borderRadius(10)
              .backgroundColor('#F0F2F5')
              .onClick(async () => {
                await CartStore.add(line.item.productId, 1);
                this.reload();
              })
          }
          .padding(12)
          .backgroundColor('#F6F7F9')
          .borderRadius(12)
        }, (line: CartLine) => String(line.item.productId))

        if (!this.loading && this.lines.length === 0) {
          Text('购物车为空').fontSize(13).fontColor('#999').width('100%').textAlign(TextAlign.Center).padding(24)
        }

        SectionTitle({ title: '收货信息' })
        Field({ label: '地址', placeholder: '请输入收货地址', value: this.address, onChange: (v: string) => this.address = v })
        Field({ label: '联系人', placeholder: '姓名', value: this.contactName, onChange: (v: string) => this.contactName = v })
        Field({ label: '电话', placeholder: '手机号', value: this.contactPhone, onChange: (v: string) => this.contactPhone = v, type: InputType.PhoneNumber })

        Text(`合计：￥${this.totalAmount().toFixed(2)}`).fontSize(14).fontColor('#333').fontWeight(FontWeight.Medium)
        PrimaryButton({ text: this.submitting ? '提交中…' : '提交订单', disabled: this.submitting, action: () => this.submitOrder() })
      }
      .padding(16)
      .width('100%')
    }
    .height('100%')
    .width('100%')
  }
}
