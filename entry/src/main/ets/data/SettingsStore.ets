import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

export interface AppLimitEntry {
  token: string;
  minutes: number;
}

export interface TictocSettingsSnapshot {
  appTokens: string[];
  immediateTokens: string[];
  whitelistTokens: string[];
  appLimits: AppLimitEntry[];
  downtime: string;
  downtimeStart: string;
  downtimeEnd: string;
  pinSalt: string;
  pinHash: string;
  defaultPinHintShown: boolean;
}

export class SettingsStore {
  private static readonly STORE_NAME: string = 'tictoc_settings';
  private static readonly KEY_APP_TOKENS: string = 'app_tokens';
  private static readonly KEY_IMMEDIATE_TOKENS: string = 'immediate_tokens';
  private static readonly KEY_WHITELIST_TOKENS: string = 'whitelist_tokens';
  private static readonly KEY_APP_LIMITS: string = 'app_limits';
  private static readonly KEY_DOWNTIME: string = 'downtime';
  private static readonly KEY_DOWNTIME_START: string = 'downtime_start';
  private static readonly KEY_DOWNTIME_END: string = 'downtime_end';
  private static readonly KEY_PIN_SALT: string = 'pin_salt';
  private static readonly KEY_PIN_HASH: string = 'pin_hash';
  private static readonly KEY_DEFAULT_PIN_HINT: string = 'default_pin_hint_shown';

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
    const appTokens = await this.readStringArray(SettingsStore.KEY_APP_TOKENS);
    const immediateTokens = await this.readStringArray(SettingsStore.KEY_IMMEDIATE_TOKENS);
    const whitelistTokens = await this.readStringArray(SettingsStore.KEY_WHITELIST_TOKENS);
    const appLimits = await this.readAppLimits(appTokens);
    const start = await data.get(SettingsStore.KEY_DOWNTIME_START, '22:00') as string;
    const end = await data.get(SettingsStore.KEY_DOWNTIME_END, '07:00') as string;
    const rawDowntime = await data.get(SettingsStore.KEY_DOWNTIME, '') as string;
    const downtime = rawDowntime.length > 0 ? rawDowntime : '';
    return {
      appTokens: appTokens,
      immediateTokens: immediateTokens,
      whitelistTokens: whitelistTokens,
      appLimits: appLimits,
      downtime: downtime,
      downtimeStart: start,
      downtimeEnd: end,
      pinSalt: await data.get(SettingsStore.KEY_PIN_SALT, '') as string,
      pinHash: await data.get(SettingsStore.KEY_PIN_HASH, '') as string,
      defaultPinHintShown: (await data.get(SettingsStore.KEY_DEFAULT_PIN_HINT, false) as boolean)
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

  public async saveWhitelistTokens(tokens: string[]): Promise<void> {
    await this.getStore().put(SettingsStore.KEY_WHITELIST_TOKENS, JSON.stringify(tokens));
    await this.getStore().flush();
  }

  public async saveAppLimits(limits: AppLimitEntry[]): Promise<void> {
    await this.getStore().put(SettingsStore.KEY_APP_LIMITS, JSON.stringify(limits));
    const tokens: string[] = [];
    for (let index = 0; index < limits.length; index++) {
      tokens.push(limits[index].token);
    }
    await this.getStore().put(SettingsStore.KEY_APP_TOKENS, JSON.stringify(tokens));
    await this.getStore().flush();
  }

  public async saveDowntime(downtime: string, start: string, end: string): Promise<void> {
    const data = this.getStore();
    await data.put(SettingsStore.KEY_DOWNTIME, downtime);
    await data.put(SettingsStore.KEY_DOWNTIME_START, start);
    await data.put(SettingsStore.KEY_DOWNTIME_END, end);
    await data.flush();
  }

  public async savePin(salt: string, hash: string): Promise<void> {
    const data = this.getStore();
    await data.put(SettingsStore.KEY_PIN_SALT, salt);
    await data.put(SettingsStore.KEY_PIN_HASH, hash);
    await data.flush();
  }

  public async markDefaultPinHintShown(): Promise<void> {
    await this.getStore().put(SettingsStore.KEY_DEFAULT_PIN_HINT, true);
    await this.getStore().flush();
  }

  public async clearPin(): Promise<void> {
    const data = this.getStore();
    await data.delete(SettingsStore.KEY_PIN_SALT);
    await data.delete(SettingsStore.KEY_PIN_HASH);
    await data.flush();
  }

  private async readStringArray(key: string): Promise<string[]> {
    const raw = await this.getStore().get(key, '[]') as string;
    try {
      const parsed: Object = JSON.parse(raw) as Object;
      if (!Array.isArray(parsed)) {
        return [];
      }
      const values: string[] = [];
      const items: Object[] = parsed as Object[];
      for (let index = 0; index < items.length; index++) {
        values.push(`${items[index]}`);
      }
      return values;
    } catch (error) {
      return [];
    }
  }

  private async readAppLimits(appTokens: string[]): Promise<AppLimitEntry[]> {
    const raw = await this.getStore().get(SettingsStore.KEY_APP_LIMITS, '[]') as string;
    let parsed: AppLimitEntry[] = [];
    try {
      const decoded: Object = JSON.parse(raw) as Object;
      parsed = Array.isArray(decoded) ? decoded as AppLimitEntry[] : [];
    } catch (error) {
      parsed = [];
    }
    const result: AppLimitEntry[] = [];
    const seen: string[] = [];
    for (let index = 0; index < parsed.length; index++) {
      const item = parsed[index];
      if (item !== undefined && item.token.length > 0 && item.minutes > 0 && seen.indexOf(item.token) < 0) {
        seen.push(item.token);
        result.push({ token: item.token, minutes: item.minutes });
      }
    }
    for (let index = 0; index < appTokens.length; index++) {
      const token = appTokens[index];
      if (seen.indexOf(token) < 0) {
        seen.push(token);
        result.push({ token: token, minutes: 60 });
      }
    }
    return result;
  }
}
