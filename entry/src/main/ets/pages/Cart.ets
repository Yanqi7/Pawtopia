import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Product } from '../model/Models';
import { CartStore, CartItem } from '../store/CartStore';
import { SessionStore } from '../store/SessionStore';
import { EmptyState, Field, OfflineBanner, TopBar } from '../components/Ui';
import { MediaAssets } from '../assets/MediaAssets';
import { Theme } from '../common/Theme';
import { priceLabel, productCategoryLabel } from '../common/Formatters';
import { AppPrompt } from '../common/AppPrompt';
import { AppStatus } from '../app/AppStatus';

interface CartLine {
  item: CartItem;
  product?: Product;
}

interface MainTabRouteParams {
  tab: number;
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
  @State private totalAmt: number = 0;
  @State private totalCnt: number = 0;

  aboutToAppear(): void {
    AppRouter.bind(this);
    const user = SessionStore.getUser();
    this.contactName = user?.nickname ?? this.contactName;
    this.contactPhone = user?.phone ?? this.contactPhone;
    this.reload();
  }

  private recalc(): void {
    let amt = 0;
    let cnt = 0;
    this.lines.forEach((line: CartLine) => {
      cnt += line.item.quantity;
      if (line.product) {
        const raw = Number(String(line.product.price ?? 0));
        amt += Number.isNaN(raw) ? 0 : raw * line.item.quantity;
      }
    });
    this.totalAmt = amt;
    this.totalCnt = cnt;
  }

  private async reload(): Promise<void> {
    this.loading = true;
    this.errorText = '';
    try {
      const items = CartStore.list();
      const products = await Promise.all(
        items.map((it: CartItem) => Api.getProduct(it.productId).catch(() => undefined))
      );
      const nextLines: CartLine[] = [];
      let missingCount = 0;
      let changed = false;
      const removedIds: number[] = [];
      items.forEach((item: CartItem, index: number) => {
        const product = products[index];
        if (!product) {
          missingCount += 1;
          nextLines.push({ item: item, product: undefined });
          return;
        }
        const stock = Math.max(0, product.stockQuantity ?? 0);
        const nextQty = Math.max(0, Math.min(item.quantity, stock));
        if (nextQty !== item.quantity) {
          changed = true;
        }
        if (nextQty <= 0) {
          removedIds.push(item.productId);
          return;
        }
        nextLines.push({ item: { productId: item.productId, quantity: nextQty }, product: product });
      });
      if (changed) {
        for (let i = 0; i < nextLines.length; i++) {
          const line = nextLines[i];
          if (line.product) {
            await CartStore.setQuantity(line.item.productId, line.item.quantity);
          }
        }
        for (let i = 0; i < removedIds.length; i++) {
          await CartStore.setQuantity(removedIds[i], 0);
        }
      }
      this.lines = nextLines;
      this.recalc();
      if (missingCount > 0) {
        this.errorText = `购物车中有 ${missingCount} 件商品已失效，请先移除后再结算`;
      } else if (changed) {
        this.errorText = '部分商品数量已按最新库存自动调整';
      }
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private hasInvalidLines(): boolean {
    return this.lines.some((line: CartLine) => !line.product);
  }

  // 直接更新本地 lines，不走 reload()，实现实时刷新
  private async adjustQuantity(productId: number, delta: number): Promise<void> {
    const idx = this.lines.findIndex((l: CartLine) => l.item.productId === productId);
    if (idx < 0) {
      return;
    }
    const line = this.lines[idx];
    if (!line.product) {
      this.errorText = '该商品已失效，请先移除';
      return;
    }
    const stock = Math.max(0, line.product.stockQuantity ?? 0);
    if (stock <= 0 && delta > 0) {
      this.errorText = '该商品当前无库存';
      return;
    }
    const next = Math.max(0, Math.min(stock, line.item.quantity + delta));
    if (next === 0) {
      // 数量减到0，直接移除
      await this.remove(productId);
      return;
    }
    try {
      await CartStore.setQuantity(productId, next);
      // 直接替换数组元素触发 @State 更新
      const updated: CartLine[] = [];
      for (let i = 0; i < this.lines.length; i++) {
        if (this.lines[i].item.productId === productId) {
          updated.push({ item: { productId: productId, quantity: next }, product: line.product });
        } else {
          updated.push(this.lines[i]);
        }
      }
      this.lines = updated;
      this.recalc();
      this.errorText = '';
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '更新数量失败';
    }
  }

  private async remove(productId: number): Promise<void> {
    try {
      await CartStore.setQuantity(productId, 0);
      this.lines = this.lines.filter((l: CartLine) => l.item.productId !== productId);
      this.recalc();
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '移除失败';
    }
  }

  private async clearCart(): Promise<void> {
    try {
      await CartStore.clear();
      this.lines = [];
      this.recalc();
      AppPrompt.toast('购物车已清空', this);
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '清空失败';
    }
  }

  private async submitOrder(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      AppRouter.replace('pages/Login', undefined, this);
      return;
    }
    if (this.lines.length === 0) {
      this.errorText = '购物车为空';
      return;
    }
    if (this.hasInvalidLines()) {
      this.errorText = '购物车中有已失效商品，请先移除后再结算';
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
        totalAmount: this.totalAmt.toFixed(2),
        status: 'PENDING',
        shippingAddress: this.address.trim(),
        contactName: this.contactName.trim(),
        contactPhone: this.contactPhone.trim()
      });
      await CartStore.clear();
      this.lines = [];
      this.recalc();
      AppRouter.replace('pages/Orders', undefined, this);
    } catch (e) {
      this.errorText = e instanceof Error ? e.message : '下单失败';
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Column() {
      // 顶部栏
      Row({ space: 12 }) {
        Image($r('app.media.hero_back'))
          .width(22).height(22)
          .onClick(() => AppRouter.back(this))
        Text('购物车')
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor(Theme.textPrimary)
          .layoutWeight(1)
        if (this.lines.length > 0) {
          Text('清空')
            .fontSize(13).fontColor(Theme.danger)
            .onClick(() => this.clearCart())
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 12 })
      .backgroundColor(Color.White)

      if (!AppStatus.isBackendOnline()) {
        OfflineBanner({ text: '当前无法连接服务，库存与下单结果可能不是最新状态。', action: () => this.reload() })
          .margin({ left: 16, right: 16, top: 8 })
      }

      if (this.errorText) {
        Text(this.errorText)
          .fontSize(12).fontColor(Theme.danger)
          .padding({ left: 16, right: 16, top: 6 })
          .width('100%')
      }

      if (!this.loading && this.lines.length === 0) {
        EmptyState({
          title: '购物车还是空的',
          description: '去商城挑一些主粮、玩具和护理用品吧。',
          actionText: '去商城逛逛',
          action: () => AppRouter.replace('pages/MainTabs', { tab: 3 } as MainTabRouteParams, this)
        })
      } else {
        Scroll() {
          Column({ space: 0 }) {
            // 商品列表
            ForEach(this.lines, (line: CartLine) => {
              Row({ space: 12 }) {
                Image(MediaAssets.productImage(line.product?.image, line.item.productId, line.product?.category))
                  .width(80).height(80).borderRadius(12).objectFit(ImageFit.Cover)

                Column({ space: 6 }) {
                  Text(line.product?.name ?? `商品 #${line.item.productId}`)
                    .fontSize(14).fontWeight(FontWeight.Medium).fontColor(Theme.textPrimary)
                    .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
                  Text(line.product ? productCategoryLabel(line.product.category) : '商品已失效')
                    .fontSize(11).fontColor(line.product ? Theme.textSecondary : Theme.danger)
                  Row({ space: 0 }) {
                    Text(`￥${priceLabel(line.product?.price as number | string | object | undefined)}`)
                      .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#E4393C')
                      .layoutWeight(1)
                    // 数量控制
                    Row({ space: 0 }) {
                      Text('－')
                        .width(28).height(28).textAlign(TextAlign.Center)
                        .fontSize(16).fontColor(Theme.textSecondary)
                        .backgroundColor('#F5F5F5').borderRadius({ topLeft: 6, bottomLeft: 6, topRight: 0, bottomRight: 0 })
                        .enabled(!!line.product)
                        .onClick(() => this.adjustQuantity(line.item.productId, -1))
                      Text(String(line.item.quantity))
                        .width(36).height(28).textAlign(TextAlign.Center)
                        .fontSize(13).fontWeight(FontWeight.Medium)
                        .backgroundColor(Color.White)
                        .border({ width: 1, color: '#EEEEEE' })
                      Text('＋')
                        .width(28).height(28).textAlign(TextAlign.Center)
                        .fontSize(16).fontColor(Theme.primary)
                        .backgroundColor('#F5F5F5').borderRadius({ topLeft: 0, bottomLeft: 0, topRight: 6, bottomRight: 6 })
                        .enabled(!!line.product && (line.product.stockQuantity ?? 0) > 0)
                        .onClick(() => this.adjustQuantity(line.item.productId, 1))
                    }
                  }
                  .width('100%').alignItems(VerticalAlign.Center)
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Start)
                Text('×')
                  .fontSize(18).fontColor(Theme.textMuted).padding(4)
                  .onClick(() => this.remove(line.item.productId))
              }
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .backgroundColor(Color.White)
              .border({ width: 0, color: 'transparent' })
              Divider().color('#F5F5F5').strokeWidth(1).margin({ left: 16 })
            }, (line: CartLine) => `${line.item.productId}_${line.item.quantity}`)

            // 收货信息
            Column({ space: 10 }) {
              Text('收货信息')
                .fontSize(15).fontWeight(FontWeight.Bold).fontColor(Theme.textPrimary).width('100%')
              Field({ label: '收货地址', placeholder: '请输入收货地址', value: this.address, onChange: (v: string) => this.address = v })
              Field({ label: '联系人', placeholder: '姓名', value: this.contactName, onChange: (v: string) => this.contactName = v })
              Field({ label: '手机号', placeholder: '手机号', value: this.contactPhone, onChange: (v: string) => this.contactPhone = v, type: InputType.PhoneNumber })
            }
            .padding(16).backgroundColor(Color.White).margin({ top: 8 }).width('100%')

            Blank().height(100)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
      }

      if (this.loading) {
        Row({ space: 8 }) {
          LoadingProgress().width(18).height(18).color(Theme.primary)
          Text('正在同步购物车…').fontSize(12).fontColor(Theme.textMuted)
        }
        .width('100%').justifyContent(FlexAlign.Center).padding(16)
      }

      // 底部结算栏（淘宝风格）
      if (this.lines.length > 0) {
        Row({ space: 12 }) {
          Column({ space: 2 }) {
            Row({ space: 4 }) {
              Text('合计：').fontSize(13).fontColor(Theme.textSecondary)
              Text(`￥${this.totalAmt.toFixed(2)}`)
                .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#E4393C')
            }
            Text(`共 ${this.totalCnt} 件商品`)
              .fontSize(11).fontColor(Theme.textMuted)
          }
          .layoutWeight(1).alignItems(HorizontalAlign.Start)
          Button(this.submitting ? '提交中…' : '去结算')
            .height(44).padding({ left: 28, right: 28 })
            .backgroundColor(this.submitting || this.hasInvalidLines() ? Theme.disabled : '#E4393C')
            .fontColor(Color.White).fontSize(16).fontWeight(FontWeight.Bold)
            .borderRadius(22)
            .enabled(!this.submitting && !this.hasInvalidLines())
            .onClick(() => this.submitOrder())
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(Color.White)
        .border({ width: 1, color: Theme.border })
      }
    }
    .height('100%').width('100%').backgroundColor('#F5F5F5')
  }
}
