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
  @State private selectedPet: string = '狗狗';
  @State private selectedCategory: string = '';

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
      const searchKeyword = this.keyword.trim() || this.selectedPet;
      const res = searchKeyword
        ? await Api.searchProducts(searchKeyword, this.page, 10)
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
      // Top search bar
      Row({ space: 8 }) {
        TextInput({ placeholder: '搜索宠物用品、食品...' })
          .layoutWeight(1)
          .height(40)
          .backgroundColor('#F0F2F5')
          .borderRadius(10)
          .padding({ left: 12 })
          .onChange((v: string) => this.keyword = v)
        Button()
          .width(40)
          .height(40)
          .borderRadius(10)
          .backgroundColor('transparent')
          .overlay(Image($r('app.media.zhaoxiangji')).width(20).height(20), Alignment.Center)
        Stack() {
          Button()
            .width(40)
            .height(40)
            .borderRadius(10)
            .backgroundColor('#2B7FFF')
            .overlay(Image($r('app.media.gouwuche')).width(20).height(20).fillColor(Color.White), Alignment.Center)
            .onClick(() => router.pushUrl({ url: 'pages/Cart' }))
          if (this.cartCount > 0) {
            Text(String(this.cartCount))
              .fontSize(10)
              .fontColor(Color.White)
              .backgroundColor(Color.Red)
              .borderRadius(10)
              .padding({ left: 4, right: 4, top: 2, bottom: 2 })
              .position({ right: -8, top: -8 })
          }
        }.width(40).height(40)
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // Promo tags
      Scroll(ScrollDirection.Horizontal) {
        Row({ space: 8 }) {
          Row() {
            Text('今日特惠').fontSize(12).fontColor('#2B7FFF')
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(16)
          .border({ width: 1, color: '#2B7FFF' })

          Row() {
            Text('新品上架').fontSize(12).fontColor(Color.White)
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(16)
          .backgroundColor('#2B7FFF')

          Row() {
            Text('宠物医院合作').fontSize(12).fontColor('#FF9D4E')
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(16)
          .border({ width: 1, color: '#FF9D4E' })
        }
        .padding({ left: 16, right: 16, bottom: 12 })
      }

      if (!AppStatus.isBackendOnline()) {
        OfflineBanner({ action: () => router.pushUrl({ url: 'pages/Login' }) })
          .padding({ left: 16, right: 16, bottom: 10 })
      }

      if (this.errorText) {
        Text(this.errorText).fontSize(13).fontColor(Color.Red).padding(16)
      }

      // Two-panel layout
      Row() {
        // Left sidebar
        Scroll() {
          Column() {
            ForEach(this.petTypes, (type: string) => {
              Button(type)
                .width('100%')
                .height(36)
                .fontSize(12)
                .backgroundColor(this.selectedPet === type ? '#2B7FFF' : '#F0F2F5')
                .fontColor(this.selectedPet === type ? Color.White : '#333')
                .onClick(() => { this.selectedPet = type; this.refresh(); })
                .margin({ bottom: 8 })
            })
          }
          .padding(8)
        }
        .width(80)
        .backgroundColor('#F9F9F9')

        // Right content
        Column() {
          // Category tabs
          Row({ space: 8 }) {
            ForEach(['食品', '玩具', '服饰', '健康护理'], (cat: string) => {
              Button(cat)
                .height(32)
                .fontSize(11)
                .backgroundColor(this.selectedCategory === cat ? '#2B7FFF' : '#F0F2F5')
                .fontColor(this.selectedCategory === cat ? Color.White : '#666')
                .onClick(() => { this.selectedCategory = cat; this.refresh(); })
            })
          }
          .padding({ left: 12, right: 12, bottom: 12 })
          .layoutWeight(0)

          // Product list
          List() {
            ForEach(this.products, (p: Product) => {
              ListItem() {
                Row({ space: 10 }) {
                  Image($r('app.media.dog')).width(60).height(60).borderRadius(8).objectFit(ImageFit.Cover)
                  Column({ space: 4 }) {
                    Row() {
                      Text(p.name).fontSize(12).fontWeight(FontWeight.Medium).layoutWeight(1)
                      Text('新').fontSize(10).fontColor(Color.White).backgroundColor(Color.Red).padding({ left: 4, right: 4 }).borderRadius(2)
                    }
                    Text(p.description ?? '').fontSize(11).fontColor('#666').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`￥${p.price}`).fontSize(13).fontWeight(FontWeight.Medium).fontColor(Color.Red)
                    Row() {
                      Text(`好评率${Math.floor(Math.random() * 30 + 70)}%`).fontSize(10).fontColor('#999')
                      Blank()
                      Button('+')
                        .width(24)
                        .height(24)
                        .fontSize(12)
                        .backgroundColor('#F0F2F5')
                        .fontColor('#666')
                        .borderRadius(4)
                    }
                  }
                  .layoutWeight(1)
                }
              }
            }, (p: Product) => String(p.id))

            ListItem() {
              if (this.last) {
                Text('没有更多了').fontSize(12).fontColor('#999').width('100%').textAlign(TextAlign.Center).padding(12)
              } else {
                Text(this.loading ? '加载中…' : '上拉加载更多').fontSize(12).fontColor('#999').width('100%').textAlign(TextAlign.Center).padding(12)
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
  }
}
