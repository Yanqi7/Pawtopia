import router from '@ohos.router';
import { SessionStore } from '../store/SessionStore';
import promptAction from '@ohos.promptAction';
import { Api } from '../api/Api';
import { AppStatus } from '../app/AppStatus';

@Entry
@Component
struct Index {
  @State private didNavigate: boolean = false;
  @State private errorText: string = '';
  @State private statusText: string = '正在启动…';

  onPageShow(): void {
    if (this.didNavigate) {
      return;
    }
    this.didNavigate = true;
    const context = getContext(this);
    SessionStore.init(context).then(() => {
      this.statusText = '正在自动登录…';
      if (SessionStore.isLoggedIn() && SessionStore.getToken()) {
        router.replaceUrl({ url: 'pages/MainTabs' });
        return;
      }
      Api.login('user1', 'user1').then(() => {
        router.replaceUrl({ url: 'pages/MainTabs' });
      }).catch(() => {
        AppStatus.setBackendOnline(false);
        promptAction.showToast({ message: '无法连接后端或登录失败，请在“我的-去设置”配置服务器地址。' });
        router.replaceUrl({ url: 'pages/MainTabs' });
      });
    }).catch((e: Error) => {
      this.errorText = e.message || '初始化失败';
      this.didNavigate = false;
    });
  }

  build() {
    Column({ space: 12 }) {
      Text('Pawtopia')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
      Text(this.errorText ? this.errorText : this.statusText)
        .fontSize(14)
        .fontColor(this.errorText ? Color.Red : Color.Grey)
    }
    .height('100%')
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(24)
  }
}
