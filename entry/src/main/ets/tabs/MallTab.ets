import router from '@ohos.router';
import { Api } from '../api/Api';
import { Product } from '../model/Models';
import { CartStore } from '../store/CartStore';
import { AppStatus } from '../app/AppStatus';
import { OfflineBanner } from '../components/Ui';

@Component
export struct MallTab {
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private products: Product[] = [];
  @State private page: number = 0;
  @State private last: boolean = false;
  @State private keyword: string = '';
  @State private cartCount: number = 0;

  aboutToAppear(): void {
    this.cartCount = CartStore.getTotalCount();
    if (this.products.length === 0) {
      this.refresh();
    }
  }

  private async refresh(): Promise<void> {
    this.page = 0;
    this.last = false;
    await this.loadPage(true);
  }

  private async loadMore(): Promise<void> {
    if (this.loading || this.last) {
      return;
    }
    this.page += 1;
    await this.loadPage(false);
  }

  private async loadPage(reset: boolean): Promise<void> {
    this.loading = true;
    this.errorText = '';
    try {
      const res = this.keyword.trim()
        ? await Api.searchProducts(this.keyword.trim(), this.page, 10)
        : await Api.getProducts(this.page, 10);
      this.last = res.last;
      this.products = reset ? res.content : [...this.products, ...res.content];
    } catch (e) {
      this.errorText = (e as Error).message || '加载失败';
    } finally {
      this.loading = false;
      this.cartCount = CartStore.getTotalCount();
    }
  }

  build() {
    Column() {
      Row() {
        Column({ space: 2 }) {
          Text('商城')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Text('精选好物，放心下单')
            .fontSize(11)
            .fontColor('#888')
        }
        Blank()
        Button(`购物车(${this.cartCount})`)
          .height(32)
          .borderRadius(16)
          .backgroundColor('#2B7FFF')
          .fontColor(Color.White)
          .onClick(() => router.pushUrl({ url: 'pages/Cart' }))
      }
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      if (!AppStatus.isBackendOnline()) {
        OfflineBanner({ action: () => router.pushUrl({ url: 'pages/Login' }) })
          .padding({ left: 16, right: 16, bottom: 10 })
      }

      Row({ space: 10 }) {
        TextInput({ placeholder: '搜索商品', text: this.keyword })
          .height(40)
          .backgroundColor('#F6F7F9')
          .borderRadius(10)
          .padding({ left: 12, right: 12 })
          .layoutWeight(1)
          .onChange((v: string) => this.keyword = v)
        Button('搜索')
          .height(40)
          .borderRadius(10)
          .backgroundColor('#2B7FFF')
          .fontColor(Color.White)
          .onClick(() => this.refresh())
      }
      .padding({ left: 16, right: 16, bottom: 10 })

      if (this.errorText) {
        Text(this.errorText).fontSize(13).fontColor(Color.Red).padding({ left: 16, right: 16, bottom: 8 })
      }

      List() {
        ForEach(this.products, (p: Product) => {
          ListItem() {
            Row({ space: 12 }) {
              Column({ space: 6 }) {
                Text(p.name).fontSize(16).fontWeight(FontWeight.Medium).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(p.description ?? '暂无描述').fontSize(13).fontColor('#666').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`￥${p.price}  库存 ${p.stockQuantity}  ${p.category}`)
                  .fontSize(12)
                  .fontColor('#999')
              }.layoutWeight(1)
              Column({ space: 8 }) {
                Text(p.category)
                  .fontSize(11)
                  .fontColor('#2B7FFF')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#EAF2FF')
                  .borderRadius(10)
                  .textAlign(TextAlign.Center)
                Button('详情')
                  .height(32)
                  .borderRadius(16)
                  .backgroundColor('#F0F2F5')
                  .onClick(() => {
                    if (p.id) {
                      router.pushUrl({ url: 'pages/ProductDetail', params: { id: p.id } });
                    }
                  })
              }
            }
            .padding(12)
            .backgroundColor('#F6F7F9')
            .borderRadius(12)
          }
          .padding({ left: 16, right: 16, bottom: 10 })
        }, (p: Product) => String(p.id))

        ListItem() {
          if (this.last) {
            Text('没有更多了').fontSize(12).fontColor('#999').width('100%').textAlign(TextAlign.Center).padding(12)
          } else {
            Text(this.loading ? '加载中…' : '上拉加载更多')
              .fontSize(12)
              .fontColor('#999')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(12)
          }
        }
      }
      .onReachEnd(() => this.loadMore())
    }
    .height('100%')
    .width('100%')
  }
}
