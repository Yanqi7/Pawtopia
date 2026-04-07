import router from '@ohos.router';

export class AppRouter {
  static push(url: string, params?: Object): void {
    router.pushUrl({ url, params });
  }

  static replace(url: string, params?: Object): void {
    router.replaceUrl({ url, params });
  }

  static back(): void {
    router.back();
  }

  static params<T>(): T {
    return router.getParams() as T;
  }
}
