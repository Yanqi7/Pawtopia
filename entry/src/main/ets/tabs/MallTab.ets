import { AppRouter } from '../common/AppRouter';
import { Api } from '../api/Api';
import { Product } from '../model/Models';
import { CartStore } from '../store/CartStore';
import { AppStatus } from '../app/AppStatus';
import { OfflineBanner } from '../components/Ui';

interface ProductDetailParams {
  id?: number;
}

@Component
export struct MallTab {
  @State private loading: boolean = false;
  @State private errorText: string = '';
  @State private products: Product[] = [];
  @State private page: number = 0;
  @State private last: boolean = false;
  @State private keyword: string = '';
  @State private cartCount: number = 0;
  @State private selectedPet: string = '狗狗';

  private petTypes = ['狗狗', '猫咪', '小宠', '水族', '鸟类', '爬宠', '通用用品'];

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
      const res = await Api.getProducts(this.page, 10);
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
      // 蓝色顶部搜索栏区域
      Column({ space: 8 }) {
        // 搜索栏 + 购物车 + 相机
        Row({ space: 8 }) {
          // 搜索栏
          Row() {
            Image($r('app.media.fangdajing'))
              .width(16)
              .height(16)
              .fillColor('#666')
              .margin({ left: 12 })
            TextInput({ placeholder: '搜索宠物用品、食品...' })
              .layoutWeight(1)
              .height(40)
              .backgroundColor('transparent')
              .fontSize(14)
              .border({ width: 0 })
          }
          .layoutWeight(1)
          .height(40)
          .padding({ right: 12 })
          .backgroundColor(Color.White)
          .borderRadius(8)

          // 购物车按钮
          Stack() {
            Button()
              .width(40)
              .height(40)
              .borderRadius(8)
              .backgroundColor('#2B7FFF')
              .onClick(() => AppRouter.push('pages/Cart'))
            Image($r('app.media.gouwuche'))
              .width(20)
              .height(20)
              .fillColor(Color.White)
            if (this.cartCount > 0) {
              Text(String(this.cartCount))
                .fontSize(10)
                .fontColor(Color.White)
                .backgroundColor(Color.Red)
                .borderRadius(10)
                .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                .position({ right: -8, top: -8 })
            }
          }

          // 相机按钮
          Button()
            .width(40)
            .height(40)
            .borderRadius(8)
            .backgroundColor('transparent')
          Image($r('app.media.zhaoxiangji'))
            .width(20)
            .height(20)
            .fillColor('#2B7FFF')
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        // 标签
        Scroll() {
          Row({ space: 8 }) {
            Button('今日特惠')
              .height(32)
              .fontSize(12)
              .backgroundColor(Color.White)
              .fontColor('#2B7FFF')
              .borderRadius(16)
              .border({ width: 1, color: '#2B7FFF' })
            Button('新品上架')
              .height(32)
              .fontSize(12)
              .backgroundColor('#2B7FFF')
              .fontColor(Color.White)
              .borderRadius(16)
            Button('宠物医院合作')
              .height(32)
              .fontSize(12)
              .backgroundColor(Color.White)
              .fontColor('#FF9D4E')
              .borderRadius(16)
              .border({ width: 1, color: '#FF9D4E' })
          }
          .padding({ left: 16, right: 16, bottom: 8 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .backgroundColor('#3B9AFF')

      if (!AppStatus.isBackendOnline()) {
        OfflineBanner({ action: () => AppRouter.push('pages/Login') })
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      }

      if (this.errorText) {
        Text(this.errorText).fontSize(13).fontColor(Color.Red).padding(16)
      }

      // 两面板布局
      Row() {
        // 左侧分类菜单
        Scroll() {
          Column() {
            ForEach(this.petTypes, (type: string) => {
              Button(type)
                .width('100%')
                .height(44)
                .fontSize(12)
                .backgroundColor(this.selectedPet === type ? '#2B7FFF' : Color.White)
                .fontColor(this.selectedPet === type ? Color.White : '#666')
                .borderRadius(0)
                .onClick(() => {this.selectedPet = type; this.refresh();})
            })
          }
          .padding(8)
        }
        .width(80)
        .backgroundColor('#F5F5F5')

        // 右侧产品列表
        Column() {
          // 产品列表
          List() {
            ForEach(this.products, (p: Product) => {
              ListItem() {
                Row({ space: 10 }) {
                  Image($r('app.media.dog'))
                    .width(60)
                    .height(60)
                    .borderRadius(8)
                    .objectFit(ImageFit.Cover)

                  Column({ space: 4 }) {
                    Row() {
                      Text(p.name)
                        .fontSize(12)
                        .fontWeight(FontWeight.Medium)
                        .layoutWeight(1)
                      Text('新')
                        .fontSize(10)
                        .fontColor(Color.White)
                        .backgroundColor(Color.Red)
                        .padding({ left: 4, right: 4 })
                        .borderRadius(2)
                    }

                    Text(p.description ?? '')
                      .fontSize(11)
                      .fontColor('#666')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Text(`￥${p.price}`)
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Color.Red)

                    Row() {
                      Text(`好评率${Math.floor(Math.random() * 30 + 70)}%`)
                        .fontSize(10)
                        .fontColor('#999')
                      Blank()
                      Button('+')
                        .width(24)
                        .height(24)
                        .fontSize(12)
                        .backgroundColor('#F0F2F5')
                        .fontColor('#666')
                        .borderRadius(4)
                        .onClick(async () => {
                          await CartStore.add(p.id ?? 0, 1);
                          this.cartCount = CartStore.getTotalCount();
                        })
                    }
                  }
                  .layoutWeight(1)
                }
              }
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .onClick(() => AppRouter.push('pages/ProductDetail', { id: p.id } as ProductDetailParams))
            }, (p: Product) => String(p.id))

            ListItem() {
              if (this.last) {
                Text('没有更多了')
                  .fontSize(12)
                  .fontColor('#999')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding(12)
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
          .layoutWeight(1)
        }
        .layoutWeight(1)
      }
      .layoutWeight(1)
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#FFFFFF')
  }
}
