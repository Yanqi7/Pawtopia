import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Product } from '../model/Models';
import { CartStore, CartItem } from '../store/CartStore';
import { SessionStore } from '../store/SessionStore';
import { ErrorText, Field } from '../components/Ui';
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
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Row() {
          Text('购物车')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Blank()
          if (this.lines.length > 0) {
            Text('清空')
              .fontSize(13)
              .fontColor('#FF5A5F')
              .margin({ right: 12 })
              .onClick(() => this.clearCart())
          }
          Text('返回')
            .fontSize(14)
            .fontColor(Theme.primary)
            .onClick(() => AppRouter.back())
        }
        .padding({ left: 16, right: 16, top: 14, bottom: 10 })

        if (this.errorText) {
          ErrorText({ text: this.errorText })
        }

        Scroll() {
          Column({ space: 12 }) {
            if (!this.loading && this.lines.length === 0) {
              Column({ space: 10 }) {
                Text('购物车还是空的')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.textPrimary)
                Text('去商城选一些粮食、玩具或护理用品吧。')
                  .fontSize(13)
                  .fontColor(Theme.textSecondary)
                Button('去商城逛逛')
                  .height(40)
                  .padding({ left: 18, right: 18 })
                  .backgroundColor('#E8F1FF')
                  .fontColor(Theme.primary)
                  .borderRadius(20)
                  .onClick(() => AppRouter.replace('pages/MainTabs'))
              }
              .padding(20)
              .backgroundColor(Color.White)
              .borderRadius(24)
            }

            ForEach(this.lines, (line: CartLine) => {
              Column({ space: 12 }) {
                Row({ space: 12 }) {
                  Image(MediaAssets.productImage(line.product?.name, line.item.productId, line.product?.category))
                    .width(96)
                    .height(96)
                    .borderRadius(18)
                    .objectFit(ImageFit.Cover)
                  Column({ space: 8 }) {
                    Text(line.product?.name ?? `商品 #${line.item.productId}`)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Theme.textPrimary)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(productCategoryLabel(line.product?.category))
                      .fontSize(11)
                      .fontColor('#FF8A3D')
                      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                      .backgroundColor('#FFF3E0')
                      .borderRadius(10)
                    Row({ space: 8 }) {
                      Text(`￥${line.product?.price ?? '-'}`)
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#FF5A5F')
                      Text(`库存 ${line.product?.stockQuantity ?? '-'}`)
                        .fontSize(11)
                        .fontColor(Theme.textMuted)
                    }
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }

                Row() {
                  Text('移除')
                    .fontSize(12)
                    .fontColor('#FF5A5F')
                    .onClick(() => this.remove(line.item.productId))
                  Blank()
                  Row({ space: 0 }) {
                    Button('-')
                      .width(34)
                      .height(30)
                      .backgroundColor('#F1F3F7')
                      .borderRadius({ topLeft: 12, bottomLeft: 12, topRight: 0, bottomRight: 0 })
                      .fontColor(Theme.textPrimary)
                      .onClick(() => this.adjustQuantity(line, -1))
                    Text(String(line.item.quantity))
                      .width(44)
                      .height(30)
                      .textAlign(TextAlign.Center)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor('#F8FAFD')
                    Button('+')
                      .width(34)
                      .height(30)
                      .backgroundColor('#F1F3F7')
                      .borderRadius({ topLeft: 0, bottomLeft: 0, topRight: 12, bottomRight: 12 })
                      .fontColor(Theme.textPrimary)
                      .onClick(() => this.adjustQuantity(line, 1))
                  }
                }
                .width('100%')
              }
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(22)
            }, (line: CartLine) => String(line.item.productId))

            if (this.lines.length > 0) {
              Column({ space: 10 }) {
                Text('收货信息')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.textPrimary)
                Field({ label: '地址', placeholder: '请输入收货地址', value: this.address, onChange: (v: string) => this.address = v })
                Field({ label: '联系人', placeholder: '姓名', value: this.contactName, onChange: (v: string) => this.contactName = v })
                Field({ label: '电话', placeholder: '手机号', value: this.contactPhone, onChange: (v: string) => this.contactPhone = v, type: InputType.PhoneNumber })
              }
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(22)
            }

            Blank().height(92)
          }
          .padding(16)
          .width('100%')
        }
        .layoutWeight(1)
      }
      .height('100%')
      .width('100%')
      .backgroundColor(Theme.background)

      if (this.lines.length > 0) {
        Row({ space: 12 }) {
          Column({ space: 4 }) {
            Text('合计')
              .fontSize(12)
              .fontColor(Theme.textSecondary)
            Text(`￥${this.totalAmount().toFixed(2)}`)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF5A5F')
          }
          .layoutWeight(1)
          Button(this.submitting ? '提交中…' : '结算')
            .width(132)
            .height(44)
            .backgroundColor(Theme.primary)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .borderRadius(22)
            .enabled(!this.submitting)
            .onClick(() => this.submitOrder())
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 18 })
        .width('100%')
        .backgroundColor('#FFFFFFF8')
      }
    }
    .height('100%')
    .width('100%')
  }
}
