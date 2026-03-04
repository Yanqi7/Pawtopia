export class AppStatus {
  private static backendOnline: boolean = true;

  static isBackendOnline(): boolean {
    return AppStatus.backendOnline;
  }

  static setBackendOnline(online: boolean): void {
    AppStatus.backendOnline = online;
  }
}

