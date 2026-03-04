import { Context } from '@kit.AbilityKit';
import { AppConfig } from '../app/AppConfig';
import { User, UserRole } from '../model/Models';
import { PreferencesStore } from './PreferencesStore';

export class SessionStore {
  private static initialized: boolean = false;
  private static user?: User;
  private static role: UserRole = AppConfig.DEFAULT_ROLE as UserRole;
  private static token: string = '';

  static async init(context: Context): Promise<void> {
    if (SessionStore.initialized) {
      return;
    }
    await PreferencesStore.init(context);
    const userText = await PreferencesStore.getString(AppConfig.PREF_KEY_SESSION_USER, '');
    const roleText = await PreferencesStore.getString(AppConfig.PREF_KEY_SESSION_ROLE, AppConfig.DEFAULT_ROLE);
    const tokenText = await PreferencesStore.getString('session_token', '');
    SessionStore.role = (roleText as UserRole) || (AppConfig.DEFAULT_ROLE as UserRole);
    if (userText) {
      try {
        SessionStore.user = JSON.parse(userText) as User;
      } catch (e) {
        SessionStore.user = undefined;
      }
    }
    SessionStore.token = tokenText || '';
    SessionStore.initialized = true;
  }

  static isLoggedIn(): boolean {
    return !!SessionStore.user?.id;
  }

  static getUser(): User | undefined {
    return SessionStore.user;
  }

  static getRole(): UserRole {
    return SessionStore.role;
  }

  static getToken(): string {
    return SessionStore.token;
  }

  static async setRole(role: UserRole): Promise<void> {
    SessionStore.role = role;
    await PreferencesStore.setString(AppConfig.PREF_KEY_SESSION_ROLE, role);
  }

  static async setBaseUrl(url: string): Promise<void> {
    await PreferencesStore.setString(AppConfig.PREF_KEY_BASE_URL, url);
  }

  static async login(user: User, role: UserRole, token: string = ''): Promise<void> {
    SessionStore.user = user;
    SessionStore.role = role;
    SessionStore.token = token || '';
    await PreferencesStore.setString(AppConfig.PREF_KEY_SESSION_USER, JSON.stringify(user));
    await PreferencesStore.setString(AppConfig.PREF_KEY_SESSION_ROLE, role);
    await PreferencesStore.setString('session_token', SessionStore.token);
  }

  static async logout(): Promise<void> {
    SessionStore.user = undefined;
    SessionStore.role = AppConfig.DEFAULT_ROLE as UserRole;
    SessionStore.token = '';
    await PreferencesStore.setString(AppConfig.PREF_KEY_SESSION_USER, '');
    await PreferencesStore.setString(AppConfig.PREF_KEY_SESSION_ROLE, AppConfig.DEFAULT_ROLE);
    await PreferencesStore.setString('session_token', '');
  }
}
