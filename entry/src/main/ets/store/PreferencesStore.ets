import preferences from '@ohos.data.preferences';
import { Context } from '@kit.AbilityKit';
import { AppConfig } from '../app/AppConfig';

export class PreferencesStore {
  private static prefs?: preferences.Preferences;

  static async init(context: Context): Promise<void> {
    if (PreferencesStore.prefs) {
      return;
    }
    try {
      PreferencesStore.prefs = await preferences.getPreferences(context, { name: AppConfig.PREFS_NAME });
    } catch (e) {
      PreferencesStore.prefs = undefined;
      const message = e instanceof Error ? e.message : '偏好存储初始化失败';
      throw new Error(message);
    }
  }

  static async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (!PreferencesStore.prefs) {
      return defaultValue;
    }
    try {
      const value = await PreferencesStore.prefs.get(key, defaultValue);
      return typeof value === 'string' ? value : defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  static async setString(key: string, value: string): Promise<void> {
    if (!PreferencesStore.prefs) {
      throw new Error('偏好存储未初始化');
    }
    try {
      await PreferencesStore.prefs.put(key, value);
      await PreferencesStore.prefs.flush();
    } catch (e) {
      const message = e instanceof Error ? e.message : '偏好存储写入失败';
      throw new Error(message);
    }
  }
}
