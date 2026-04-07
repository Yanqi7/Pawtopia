import promptAction from '@ohos.promptAction';

export class AppPrompt {
  static toast(message: string): void {
    try {
      promptAction.showToast({ message });
    } catch (e) {
    }
  }
}
