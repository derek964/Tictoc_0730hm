/*
 * Tictoc local settings. App tokens are opaque values supplied by the system picker.
 * They are kept only on this device and are never resolved into package names.
 */
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

export interface TictocSettingsSnapshot {
  appTokens: string[];
  immediateTokens: string[];
  downtimeStart: string;
  downtimeEnd: string;
  dailyMinutes: number;
  pinSalt: string;
  pinHash: string;
}

export class SettingsStore {
  private static readonly STORE_NAME: string = 'tictoc_settings';
  private static readonly KEY_APP_TOKENS: string = 'app_tokens';
  private static readonly KEY_IMMEDIATE_TOKENS: string = 'immediate_tokens';
  private static readonly KEY_DOWNTIME_START: string = 'downtime_start';
  private static readonly KEY_DOWNTIME_END: string = 'downtime_end';
  private static readonly KEY_DAILY_MINUTES: string = 'daily_minutes';
  private static readonly KEY_PIN_SALT: string = 'pin_salt';
  private static readonly KEY_PIN_HASH: string = 'pin_hash';

  private store?: preferences.Preferences;

  public async initialize(context: common.UIAbilityContext): Promise<void> {
    this.store = await preferences.getPreferences(context, SettingsStore.STORE_NAME);
  }

  private getStore(): preferences.Preferences {
    if (this.store === undefined) {
      throw new Error('SettingsStore has not been initialized');
    }
    return this.store;
  }

  public async load(): Promise<TictocSettingsSnapshot> {
    const data = this.getStore();
    const tokenJson = await data.get(SettingsStore.KEY_APP_TOKENS, '[]') as string;
    const immediateTokenJson = await data.get(SettingsStore.KEY_IMMEDIATE_TOKENS, '[]') as string;
    let appTokens: string[] = [];
    let immediateTokens: string[] = [];
    try {
      appTokens = JSON.parse(tokenJson) as string[];
    } catch (_) {
      appTokens = [];
    }
    try {
      immediateTokens = JSON.parse(immediateTokenJson) as string[];
    } catch (_) {
      immediateTokens = [];
    }
    return {
      appTokens: appTokens,
      immediateTokens: immediateTokens,
      downtimeStart: await data.get(SettingsStore.KEY_DOWNTIME_START, '22:00') as string,
      downtimeEnd: await data.get(SettingsStore.KEY_DOWNTIME_END, '07:00') as string,
      dailyMinutes: await data.get(SettingsStore.KEY_DAILY_MINUTES, 60) as number,
      pinSalt: await data.get(SettingsStore.KEY_PIN_SALT, '') as string,
      pinHash: await data.get(SettingsStore.KEY_PIN_HASH, '') as string
    };
  }

  public async saveAppTokens(tokens: string[]): Promise<void> {
    await this.getStore().put(SettingsStore.KEY_APP_TOKENS, JSON.stringify(tokens));
    await this.getStore().flush();
  }

  public async saveImmediateTokens(tokens: string[]): Promise<void> {
    await this.getStore().put(SettingsStore.KEY_IMMEDIATE_TOKENS, JSON.stringify(tokens));
    await this.getStore().flush();
  }

  public async saveRuleInputs(start: string, end: string, dailyMinutes: number): Promise<void> {
    const data = this.getStore();
    await data.put(SettingsStore.KEY_DOWNTIME_START, start);
    await data.put(SettingsStore.KEY_DOWNTIME_END, end);
    await data.put(SettingsStore.KEY_DAILY_MINUTES, dailyMinutes);
    await data.flush();
  }

  public async savePin(salt: string, hash: string): Promise<void> {
    const data = this.getStore();
    await data.put(SettingsStore.KEY_PIN_SALT, salt);
    await data.put(SettingsStore.KEY_PIN_HASH, hash);
    await data.flush();
  }

  public async clearPin(): Promise<void> {
    const data = this.getStore();
    await data.delete(SettingsStore.KEY_PIN_SALT);
    await data.delete(SettingsStore.KEY_PIN_HASH);
    await data.flush();
  }
}
