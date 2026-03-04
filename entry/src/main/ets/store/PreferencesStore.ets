import preferences from '@ohos.data.preferences';
import { Context } from '@kit.AbilityKit';
import { AppConfig } from '../app/AppConfig';

export class PreferencesStore {
  private static prefs?: preferences.Preferences;

  static async init(context: Context): Promise<void> {
    if (PreferencesStore.prefs) {
      return;
    }
    PreferencesStore.prefs = await preferences.getPreferences(context, { name: AppConfig.PREFS_NAME });
  }

  static async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (!PreferencesStore.prefs) {
      return defaultValue;
    }
    const value = await PreferencesStore.prefs.get(key, defaultValue);
    return typeof value === 'string' ? value : defaultValue;
  }

  static async setString(key: string, value: string): Promise<void> {
    if (!PreferencesStore.prefs) {
      return;
    }
    await PreferencesStore.prefs.put(key, value);
    await PreferencesStore.prefs.flush();
  }
}
