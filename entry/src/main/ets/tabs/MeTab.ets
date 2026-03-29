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
        // Header with user info
        Column({ space: 12 }) {
          Row() {
            Column({ space: 4 }) {
              Image($r('app.media.people'))
                .width(60)
                .height(60)
                .borderRadius(30)
              Text(this.user.nickname || '用户')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
            }
            .alignItems(HorizontalAlign.Center)

            Blank()

            Stack() {
              Image($r('app.media.lingdang'))
                .width(28)
                .height(28)
                .fillColor($r('sys.color.ohos_id_color_text_secondary'))
              Circle()
                .width(8)
                .height(8)
                .fill($r('sys.color.ohos_id_color_warning'))
                .position({ right: 0, top: 0 })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
        .width('100%')
        .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
        .padding({ top: 16 })

        // Menu items
        List() {
          ListItem() {
            Row({ space: 12 }) {
              Image($r('app.media.ic_switch'))
                .width(24)
                .height(24)
                .fillColor($r('sys.color.ohos_id_color_text_secondary'))
              Text('切换账号')
                .fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .layoutWeight(1)
              Text('>')
                .fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }
            .padding(16)
            .width('100%')
          }
          .onClick(() => router.pushUrl({ url: 'pages/Login' }))

          ListItem() {
            Row({ space: 12 }) {
              Image($r('app.media.ic_logout'))
                .width(24)
                .height(24)
                .fillColor($r('sys.color.ohos_id_color_warning'))
              Text('退出登录')
                .fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_warning'))
                .layoutWeight(1)
              Text('>')
                .fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }
            .padding(16)
            .width('100%')
          }
          .onClick(() => this.logout())

          ListItem() {
            Row({ space: 12 }) {
              Image($r('app.media.ic_trash'))
                .width(24)
                .height(24)
                .fillColor($r('sys.color.ohos_id_color_text_secondary'))
              Text('内存清理')
                .fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .layoutWeight(1)
              Text('23.5MB')
                .fontSize(13)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }
            .padding(16)
            .width('100%')
          }

          ListItem() {
            Row({ space: 12 }) {
              Image($r('app.media.more'))
                .width(24)
                .height(24)
                .fillColor($r('sys.color.ohos_id_color_text_secondary'))
              Text('版本信息')
                .fontSize(14)
                .fontColor($r('sys.color.ohos_id_color_text_primary'))
                .layoutWeight(1)
              Text('v2.3.1')
                .fontSize(13)
                .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            }
            .padding(16)
            .width('100%')
          }
        }
        .padding({ top: 16 })
        .layoutWeight(1)

        // Footer
        Text('© 2023 宠物之家 版权所有')
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ bottom: 20 })
      } else {
        Column() {
          Text('未登录')
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .margin({ bottom: 20 })
          Button('去登录')
            .width('60%')
            .height(44)
            .type(ButtonType.Capsule)
            .backgroundColor($r('sys.color.ohos_id_color_brand'))
            .fontColor(Color.White)
            .onClick(() => router.pushUrl({ url: 'pages/Login' }))
        }
        .height('100%')
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
