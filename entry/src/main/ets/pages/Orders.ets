import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Order, OrderStatus } from '../model/Models';
import { SessionStore } from '../store/SessionStore';
import { ErrorText, SectionTitle } from '../components/Ui';

@Entry
@Component
struct Orders {
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private orders: Order[] = [];

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    const user = SessionStore.getUser();
    if (!user || !user.id) {
      AppRouter.replace('pages/Login');
      return;
    }
    const userId = user.id;
    this.loading = true;
    this.errorText = '';
    try {
      this.orders = await Api.getMyOrders(userId);
      this.orders = [...this.orders].sort((a, b) => (b.id ?? 0) - (a.id ?? 0));
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
    }
  }

  private async setStatus(orderId: number, status: OrderStatus): Promise<void> {
    try {
      await Api.updateOrderStatus(orderId, status);
      await this.load();
    } catch (e) {
      this.errorText = (e as Error).message || '更新失败';
    }
  }

  build() {
    Column() {
      Row() {
        Text('我的订单').fontSize(18).fontWeight(FontWeight.Bold)
        Blank()
        Text('返回').fontSize(14).fontColor('#2B7FFF').onClick(() => AppRouter.back())
      }
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      if (this.errorText) {
        ErrorText({ text: this.errorText })
      }

      Scroll() {
        Column({ space: 12 }) {
          if (!this.loading && this.orders.length === 0) {
            Text('暂无订单').fontSize(13).fontColor('#999').width('100%').textAlign(TextAlign.Center).padding(24)
          }

          ForEach(this.orders, (o: Order) => {
            Column({ space: 8 }) {
              Text(`订单 #${o.id}`).fontSize(15).fontWeight(FontWeight.Medium)
              Text(`状态：${o.status}`).fontSize(12).fontColor('#666')
              Text(`金额：￥${o.totalAmount}`).fontSize(12).fontColor('#666')
              Text(`商品：${o.productIds}  数量：${o.quantities}`).fontSize(12).fontColor('#999')
              if (o.shippingAddress) {
                Text(`地址：${o.shippingAddress}`).fontSize(12).fontColor('#999')
              }
              Row({ space: 10 }) {
                if (o.status === 'PENDING') {
                  Button('取消')
                    .height(32)
                    .borderRadius(16)
                    .backgroundColor('#F0F2F5')
                    .onClick(() => {
                      if (o.id) {
                        this.setStatus(o.id, 'CANCELLED');
                      }
                    })
                  Button('标记已支付')
                    .height(32)
                    .borderRadius(16)
                    .backgroundColor('#2B7FFF')
                    .fontColor(Color.White)
                    .onClick(() => {
                      if (o.id) {
                        this.setStatus(o.id, 'PAID');
                      }
                    })
                }
              }
            }
            .padding(12)
            .backgroundColor('#F6F7F9')
            .borderRadius(12)
          }, (o: Order) => String(o.id))
        }
        .padding({ left: 16, right: 16, bottom: 24 })
        .width('100%')
      }
      .height('100%')
    }
    .height('100%')
    .width('100%')
  }
}
