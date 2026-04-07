import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Product } from '../model/Models';
import { CartStore, CartItem } from '../store/CartStore';
import { SessionStore } from '../store/SessionStore';
import { PrimaryButton, ErrorText, Field, SectionTitle } from '../components/Ui';
import { MediaAssets } from '../assets/MediaAssets';
import { Theme } from '../common/Theme';
import { productCategoryLabel } from '../common/Formatters';
import { AppPrompt } from '../common/AppPrompt';

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
    const user = SessionStore.getUser();
    this.contactName = user?.nickname ?? this.contactName;
    this.contactPhone = user?.phone ?? this.contactPhone;
    this.reload();
  }

  private async reload(): Promise<void> {
    this.loading = true;
    this.errorText = '';
    try {
      const items = CartStore.list();
      const products = await Promise.all(items.map((it: CartItem) => Api.getProduct(it.productId).catch(() => undefined)));
      this.lines = items.map((item: CartItem, index: number) => {
        const line: CartLine = { item: item, product: products[index] };
        return line;
      });
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private totalAmount(): number {
    return this.lines.reduce((sum: number, line: CartLine) => {
      const price = Number(line.product?.price ?? 0);
      return sum + (Number.isNaN(price) ? 0 : price * line.item.quantity);
    }, 0);
  }

  private async adjustQuantity(line: CartLine, delta: number): Promise<void> {
    const stock = Math.max(1, line.product?.stockQuantity ?? 99);
    const next = Math.max(0, Math.min(stock, line.item.quantity + delta));
    await CartStore.setQuantity(line.item.productId, next);
    await this.reload();
  }

  private async remove(productId: number): Promise<void> {
    await CartStore.setQuantity(productId, 0);
    await this.reload();
  }

  private async clearCart(): Promise<void> {
    await CartStore.clear();
    await this.reload();
    AppPrompt.toast('购物车已清空');
  }

  private async submitOrder(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      AppRouter.replace('pages/Login');
      return;
    }
    if (this.lines.length === 0) {
      this.errorText = '购物车为空';
      return;
    }
    if (!this.address.trim() || !this.contactName.trim() || !this.contactPhone.trim()) {
      this.errorText = '请完善收货信息';
      return;
    }
    this.submitting = true;
    this.errorText = '';
    try {
      await Api.createOrder({
        userId: user.id,
        productIds: this.lines.map((line: CartLine) => String(line.item.productId)).join(','),
        quantities: this.lines.map((line: CartLine) => String(line.item.quantity)).join(','),
        totalAmount: this.totalAmount().toFixed(2),
        status: 'PENDING',
        shippingAddress: this.address.trim(),
        contactName: this.contactName.trim(),
        contactPhone: this.contactPhone.trim()
      });
      await CartStore.clear();
      AppRouter.replace('pages/Orders');
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
          if (this.lines.length > 0) {
            Text('清空').fontSize(13).fontColor('#FF5A5F').margin({ right: 12 }).onClick(() => this.clearCart())
          }
          Text('返回').fontSize(14).fontColor(Theme.primary).onClick(() => AppRouter.back())
        }

        if (this.errorText) {
          ErrorText({ text: this.errorText })
        }

        SectionTitle({ title: `商品（${this.lines.length}）` })
        ForEach(this.lines, (line: CartLine) => {
          Row({ space: 12 }) {
            Image(MediaAssets.productImage(line.product?.image, line.item.productId, line.product?.category))
              .width(92)
              .height(92)
              .borderRadius(20)
              .objectFit(ImageFit.Cover)

            Column({ space: 8 }) {
              Text(line.product?.name ?? `商品 #${line.item.productId}`).fontSize(16).fontWeight(FontWeight.Medium)
              Text(productCategoryLabel(line.product?.category)).fontSize(11).fontColor('#FF8A3D')
              Text(`￥${line.product?.price ?? '-'} · 库存 ${line.product?.stockQuantity ?? '-'}`).fontSize(12).fontColor('#666')
              Row({ space: 10 }) {
                Button('-').height(32).width(36).borderRadius(10).backgroundColor('#F0F2F5').onClick(() => this.adjustQuantity(line, -1))
                Text(String(line.item.quantity)).fontSize(16).fontWeight(FontWeight.Bold)
                Button('+').height(32).width(36).borderRadius(10).backgroundColor('#F0F2F5').onClick(() => this.adjustQuantity(line, 1))
                Blank()
                Text('移除').fontSize(12).fontColor('#FF5A5F').onClick(() => this.remove(line.item.productId))
              }
              .width('100%')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(24)
        }, (line: CartLine) => String(line.item.productId))

        if (!this.loading && this.lines.length === 0) {
          Text('购物车为空').fontSize(13).fontColor('#999').width('100%').textAlign(TextAlign.Center).padding(24)
        }

        SectionTitle({ title: '收货信息' })
        Field({ label: '地址', placeholder: '请输入收货地址', value: this.address, onChange: (v: string) => this.address = v })
        Field({ label: '联系人', placeholder: '姓名', value: this.contactName, onChange: (v: string) => this.contactName = v })
        Field({ label: '电话', placeholder: '手机号', value: this.contactPhone, onChange: (v: string) => this.contactPhone = v, type: InputType.PhoneNumber })

        Text(`合计：￥${this.totalAmount().toFixed(2)}`).fontSize(16).fontColor('#333').fontWeight(FontWeight.Medium)
        PrimaryButton({ text: this.submitting ? '提交中…' : '提交订单', disabled: this.submitting || this.lines.length === 0, action: () => this.submitOrder() })
      }
      .padding(16)
      .width('100%')
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }
}
