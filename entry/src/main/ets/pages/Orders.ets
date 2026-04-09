import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Order, OrderStatus, Product } from '../model/Models';
import { SessionStore } from '../store/SessionStore';
import { ErrorText } from '../components/Ui';
import { Theme } from '../common/Theme';

interface OrderLine {
  order: Order;
  products: Product[];
  missingCount: number;
}

interface OrderStatusFilter {
  status: OrderStatus | 'ALL';
}

@Entry
@Component
struct Orders {
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private lines: OrderLine[] = [];
  @State private selectedStatus: OrderStatus | 'ALL' = 'ALL';

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      AppRouter.replace('pages/Login');
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      const orders = await Api.getMyOrders(user.id);
      const sorted = [...orders].sort((a: Order, b: Order) => (b.id ?? 0) - (a.id ?? 0));
      const lines = await Promise.all(sorted.map(async (order: Order) => {
        const ids = order.productIds.split(',').map((id: string) => Number(id)).filter((id: number) => id > 0);
        const products = await Promise.all(ids.map((id: number) => Api.getProduct(id).catch(() => undefined)));
        const validProducts = products.filter((item) => !!item) as Product[];
        const line: OrderLine = {
          order: order,
          products: validProducts,
          missingCount: ids.length - validProducts.length
        };
        return line;
      }));
      this.lines = lines;
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private visibleLines(): OrderLine[] {
    return this.lines.filter((line: OrderLine) => this.selectedStatus === 'ALL' || line.order.status === this.selectedStatus);
  }

  private async setStatus(orderId: number, status: OrderStatus): Promise<void> {
    try {
      await Api.updateOrderStatus(orderId, status);
      await this.load();
    } catch (e) {
      this.errorText = (e as Error).message || '更新失败';
    }
  }

  private statusLabel(status: OrderStatus): string {
    switch (status) {
      case 'PENDING':
        return '待付款';
      case 'PAID':
        return '待发货';
      case 'SHIPPED':
        return '运输中';
      case 'DELIVERED':
        return '已完成';
      case 'CANCELLED':
        return '已取消';
      default:
        return status;
    }
  }

  build() {
    Column() {
      Row() {
        Text('我的订单').fontSize(18).fontWeight(FontWeight.Bold)
        Blank()
        Text('返回').fontSize(14).fontColor(Theme.primary).onClick(() => AppRouter.back())
      }
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      Scroll() {
        Row({ space: 8 }) {
          this.StatusChip('全部', 'ALL')
          this.StatusChip('待付款', 'PENDING')
          this.StatusChip('待发货', 'PAID')
          this.StatusChip('运输中', 'SHIPPED')
          this.StatusChip('已完成', 'DELIVERED')
        }
        .padding({ left: 16, right: 16, bottom: 10 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)

      if (this.errorText) {
        ErrorText({ text: this.errorText })
      }

      Scroll() {
        Column({ space: 12 }) {
          if (!this.loading && this.visibleLines().length === 0) {
            Text('暂无订单').fontSize(13).fontColor('#999').width('100%').textAlign(TextAlign.Center).padding(24)
          }

          ForEach(this.visibleLines(), (line: OrderLine) => {
            Column({ space: 10 }) {
              Row() {
                Text(`订单 #${line.order.id}`).fontSize(15).fontWeight(FontWeight.Medium)
                Blank()
                Text(this.statusLabel(line.order.status)).fontSize(12).fontColor(Theme.primary)
              }
              Text(`金额：￥${line.order.totalAmount}`).fontSize(13).fontColor('#333')
              Text(`下单时间：${line.order.createdAt ?? '-'}`).fontSize(12).fontColor('#999')
              Text(`收货人：${line.order.contactName ?? '-'} · ${line.order.contactPhone ?? '-'}`).fontSize(12).fontColor('#999')
              if (line.order.shippingAddress) {
                Text(`地址：${line.order.shippingAddress}`).fontSize(12).fontColor('#999')
              }
              Text(`商品：${line.products.map((product: Product) => product.name).join(' / ') || line.order.productIds}`).fontSize(12).fontColor('#666')
              if (line.missingCount > 0) {
                Text(`其中有 ${line.missingCount} 件商品当前无法加载详情`).fontSize(12).fontColor('#D14343')
              }

              if (line.order.status === 'PENDING' && line.order.id) {
                Row({ space: 10 }) {
                  Button('取消')
                    .height(32)
                    .borderRadius(16)
                    .backgroundColor('#F0F2F5')
                    .onClick(() => this.setStatus(line.order.id!, 'CANCELLED'))
                  Button('标记已支付')
                    .height(32)
                    .borderRadius(16)
                    .backgroundColor(Theme.primary)
                    .fontColor(Color.White)
                    .onClick(() => this.setStatus(line.order.id!, 'PAID'))
                }
              }
            }
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(24)
          }, (line: OrderLine) => String(line.order.id))
        }
        .padding({ left: 16, right: 16, bottom: 24 })
        .width('100%')
      }
      .height('100%')
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }

  @Builder private StatusChip(label: string, status: OrderStatus | 'ALL') {
    Text(label)
      .fontSize(12)
      .fontColor(this.selectedStatus === status ? Color.White : Theme.textSecondary)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(this.selectedStatus === status ? Theme.primary : Color.White)
      .borderRadius(16)
      .onClick(() => this.selectedStatus = status)
  }
}
