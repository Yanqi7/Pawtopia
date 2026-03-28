import router from '@ohos.router';
import { SessionStore } from '../store/SessionStore';
import { Api } from '../api/Api';
import { User } from '../model/Models';
import { AppStatus } from '../app/AppStatus';

function roleLabel(role: string): string {
  return role === 'PET_SHOP' ? '宠物店' : role === 'PET_HOSPITAL' ? '宠物医院' : role === 'SELLER' ? '卖家' : role === 'ADMIN' ? '管理员' : '普通用户';
}

@Component
export struct MeTab {
  @State private user?: User = SessionStore.getUser();
  @State private loading: boolean = false;

  aboutToAppear(): void {
    this.user = SessionStore.getUser();
  }

  private async logout(): Promise<void> {
    await SessionStore.logout();
    router.replaceUrl({ url: 'pages/Login' });
  }

  build() {
    Column() {
      if (this.user) {
        // Blue gradient header
        Column({ space: 12 }) {
          Row() {
            Column({ space: 4 }) {
              Image($r('app.media.people')).width(60).height(60).borderRadius(30)
              Text(this.user.nickname || '铲屎官小A').fontSize(14).fontWeight(FontWeight.Medium).fontColor(Color.White)
            }
            .alignItems(HorizontalAlign.Center)

            Blank()

            Stack() {
              Image($r('app.media.lingdang')).width(28).height(28).fillColor(Color.White)
              Circle().width(8).height(8).fill(Color.Red).position({ right: 0, top: 0 })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
        .width('100%')
        .linearGradient({
          angle: 135,
          colors: [['#3B9AFF', 0.0], ['#2B7FFF', 1.0]]
        })
        .padding({ top: 16 })

        // Menu items
        List() {
          ListItem() {
            Row({ space: 12 }) {
              Image($r('app.media.ic_switch')).width(24).height(24)
              Text('切换账号').fontSize(14).fontColor('#333').layoutWeight(1)
              Text('>').fontSize(14).fontColor('#999')
            }
            .padding(16)
            .width('100%')
            .backgroundColor('#FFFFFF')
          }
          .onClick(() => router.pushUrl({ url: 'pages/Login' }))

          ListItem() {
            Row({ space: 12 }) {
              Image($r('app.media.ic_logout')).width(24).height(24)
              Text('退出登录').fontSize(14).fontColor(Color.Red).layoutWeight(1)
              Text('>').fontSize(14).fontColor('#999')
            }
            .padding(16)
            .width('100%')
            .backgroundColor('#FFFFFF')
          }
          .onClick(() => this.logout())

          ListItem() {
            Row({ space: 12 }) {
              Image($r('app.media.ic_trash')).width(24).height(24)
              Text('内存清理').fontSize(14).fontColor('#333').layoutWeight(1)
              Text('23.5MB').fontSize(13).fontColor('#999')
            }
            .padding(16)
            .width('100%')
            .backgroundColor('#FFFFFF')
          }

          ListItem() {
            Row({ space: 12 }) {
              Image($r('app.media.more')).width(24).height(24)
              Text('版本信息').fontSize(14).fontColor('#333').layoutWeight(1)
              Text('v2.3.1').fontSize(13).fontColor('#999')
            }
            .padding(16)
            .width('100%')
            .backgroundColor('#FFFFFF')
          }
        }
        .padding({ top: 16 })
        .layoutWeight(1)

        // Footer
        Text('© 2023 宠物之家 版权所有').fontSize(12).fontColor('#999').width('100%').textAlign(TextAlign.Center).padding({ bottom: 20 })
      } else {
        Column() {
          Text('未登录').fontSize(16).fontColor('#666').margin({ bottom: 20 })
          Button('去登录/设置服务器').width('80%').height(44).backgroundColor('#2B7FFF').fontColor(Color.White).onClick(() => router.pushUrl({ url: 'pages/Login' }))
        }
        .height('100%')
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .height('100%')
    .width('100%')
  }
}
