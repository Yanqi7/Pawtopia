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
        // 蓝色渐变顶部
        Column({ space: 12 }) {
          Row() {
            // 左侧：头像 + 用户信息
            Column({ space: 4 }) {
              Image($r('app.media.people'))
                .width(60)
                .height(60)
                .borderRadius(30)
              Text(this.user.nickname || '铲屎官小A')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
            .alignItems(HorizontalAlign.Center)

            Blank()

            // 右侧：通知铃铛
            Stack() {
              Image($r('app.media.lingdang'))
                .width(28)
                .height(28)
                .fillColor(Color.White)
              Circle()
                .width(8)
                .height(8)
                .fill(Color.Red)
                .position({ right: 0, top: 0 })
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

        // 菜单列表
        Column() {
          // 切换账号
          Row({ space: 12 }) {
            Image($r('app.media.ic_switch'))
              .width(24)
              .height(24)
              .fillColor('#666')
            Text('切换账号')
              .fontSize(14)
              .fontColor('#333')
              .layoutWeight(1)
            Text('>')
              .fontSize(16)
              .fontColor('#999')
          }
          .padding(16)
          .width('100%')
          .backgroundColor(Color.White)
          .borderBottom(1, Color.Transparent)
          .onClick(() => router.pushUrl({ url: 'pages/Login' }))

          Divider()
            .strokeWidth(1)
            .color('#EFEFEF')

          // 退出登录
          Row({ space: 12 }) {
            Image($r('app.media.ic_logout'))
              .width(24)
              .height(24)
              .fillColor(Color.Red)
            Text('退出登录')
              .fontSize(14)
              .fontColor(Color.Red)
              .layoutWeight(1)
            Text('›')
              .fontSize(24)
              .fontColor(Color.Red)
          }
          .padding(16)
          .width('100%')
          .backgroundColor(Color.White)
          .onClick(() => this.logout())

          Divider()
            .strokeWidth(1)
            .color('#EFEFEF')

          // 内存清理
          Row({ space: 12 }) {
            Image($r('app.media.ic_trash'))
              .width(24)
              .height(24)
              .fillColor('#666')
            Text('内存清理')
              .fontSize(14)
              .fontColor('#333')
              .layoutWeight(1)
            Text('23.5MB')
              .fontSize(13)
              .fontColor('#999')
          }
          .padding(16)
          .width('100%')
          .backgroundColor(Color.White)

          Divider()
            .strokeWidth(1)
            .color('#EFEFEF')

          // 版本信息
          Row({ space: 12 }) {
            Image($r('app.media.more'))
              .width(24)
              .height(24)
              .fillColor('#666')
            Text('版本信息')
              .fontSize(14)
              .fontColor('#333')
              .layoutWeight(1)
            Text('v2.3.1')
              .fontSize(13)
              .fontColor('#999')
          }
          .padding(16)
          .width('100%')
          .backgroundColor(Color.White)
        }
        .layoutWeight(1)

        // 底部版权信息
        Text('© 2023 宠物之家 版权所有')
          .fontSize(12)
          .fontColor('#999')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 16, bottom: 20 })
      } else {
        Column() {
          Text('未登录')
            .fontSize(16)
            .fontColor('#666')
            .margin({ bottom: 20 })
          Button('去登录')
            .width('60%')
            .height(44)
            .type(ButtonType.Capsule)
            .backgroundColor('#2B7FFF')
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
    .backgroundColor('#F5F5F5')
  }
}
