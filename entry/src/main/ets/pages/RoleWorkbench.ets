import { AppRouter } from '../common/AppRouter';
import { SessionStore } from '../store/SessionStore';
import { Theme } from '../common/Theme';
import { EmptyState } from '../components/Ui';

interface MainTabParams {
  tab?: number;
}

function roleLabel(role: string): string {
  return role === 'PET_SHOP' ? '宠物店工作台' : role === 'PET_HOSPITAL' ? '宠物医院工作台' : role === 'SELLER' ? '卖家工作台' : role === 'ADMIN' ? '管理员工作台' : '普通用户工作台';
}

@Entry
@Component
struct RoleWorkbench {
  private openTab(tab: number): void {
    AppRouter.replace('pages/MainTabs', { tab: tab } as MainTabParams);
  }

  build() {
    const user = SessionStore.getUser();
    Column() {
      Row() {
        Text('角色工作台')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('返回')
          .fontSize(14)
          .fontColor(Theme.primary)
          .onClick(() => AppRouter.back())
      }
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })

      if (!user) {
        EmptyState({
          title: '请先登录',
          description: '登录后即可查看对应角色的工作台能力。',
          actionText: '去登录',
          action: () => AppRouter.replace('pages/Login')
        })
      } else {
        Scroll() {
          Column({ space: 14 }) {
            Column({ space: 8 }) {
              Text(roleLabel(user.role ?? 'USER'))
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.textPrimary)
              Text('这里汇总了你当前身份最常用的管理入口。')
                .fontSize(12)
                .fontColor(Theme.textSecondary)
            }
            .width('100%')
            .padding(18)
            .backgroundColor(Color.White)
            .borderRadius(24)

            if (user.role === 'PET_HOSPITAL') {
              this.ActionCard('健康档案维护', '查看宠物档案并新增医疗记录', () => this.openTab(2))
              this.ActionCard('订单与就诊记录', '查看商城订单与后续服务记录', () => AppRouter.push('pages/Orders'))
            } else if (user.role === 'SELLER') {
              this.ActionCard('商品与上新', '查看商品详情与商城列表', () => this.openTab(3))
              this.ActionCard('订单履约', '查看当前商城订单并跟进状态', () => AppRouter.push('pages/Orders'))
            } else if (user.role === 'PET_SHOP') {
              this.ActionCard('领养发布管理', '查看领养信息与宠物详情', () => this.openTab(1))
              this.ActionCard('宠物档案管理', '查看发布宠物与健康档案', () => this.openTab(2))
            } else if (user.role === 'ADMIN') {
              this.ActionCard('社区内容巡检', '检查社区帖子与互动内容', () => this.openTab(0))
              this.ActionCard('系统订单巡检', '查看订单列表并进行核对', () => AppRouter.push('pages/Orders'))
            } else {
              this.ActionCard('进入社区', '浏览社区、领养、档案与商城内容', () => this.openTab(0))
              this.ActionCard('查看我的档案', '维护宠物资料和健康记录', () => this.openTab(2))
            }
          }
          .padding({ left: 16, right: 16, bottom: 24 })
          .width('100%')
        }
        .layoutWeight(1)
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(Theme.background)
  }

  @Builder private ActionCard(title: string, desc: string, action: () => void) {
    Row({ space: 12 }) {
      Column()
        .width(10)
        .height(42)
        .borderRadius(5)
        .backgroundColor('#CFE2FF')
      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.textPrimary)
        Text(desc)
          .fontSize(12)
          .fontColor(Theme.textSecondary)
      }
      .layoutWeight(1)
      Text('›')
        .fontSize(22)
        .fontColor(Theme.textMuted)
    }
    .padding(16)
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(22)
    .onClick(() => action())
  }
}
