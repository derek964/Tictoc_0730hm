import { util } from '@kit.ArkTS';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export interface PinCredential {
  salt: string;
  hash: string;
}

export class PinSecurity {
  private static readonly DOMAIN: number = 0x0000;
  private static readonly TAG: string = 'PinSecurity';

  public static isValidFormat(pin: string): boolean {
    return /^\d{4,6}$/.test(pin);
  }

  public static isCompleteCredential(salt: string, hash: string): boolean {
    return salt.length > 0 && hash.length > 0;
  }

  public static isCorruptCredential(salt: string, hash: string): boolean {
    return (salt.length === 0) !== (hash.length === 0);
  }

  public static async createCredential(pin: string): Promise<PinCredential> {
    const randomData = cryptoFramework.createRandom().generateRandomSync(16).data;
    const salt = PinSecurity.toHex(randomData);
    return {
      salt: salt,
      hash: await PinSecurity.hashPin(pin, salt)
    };
  }

  public static async verify(pin: string, salt: string, expectedHash: string): Promise<boolean> {
    if (!PinSecurity.isValidFormat(pin) || !PinSecurity.isCompleteCredential(salt, expectedHash)) {
      return false;
    }
    const current = await PinSecurity.hashPin(pin, salt);
    if (PinSecurity.equal(current, expectedHash)) {
      return true;
    }
    try {
      const legacy = await PinSecurity.hashLegacyAsync(pin, salt);
      return PinSecurity.equal(legacy, expectedHash);
    } catch (error) {
      hilog.warn(PinSecurity.DOMAIN, PinSecurity.TAG, 'legacy pin hash failed');
      return false;
    }
  }

  private static async hashPin(pin: string, salt: string): Promise<string> {
    const digest = cryptoFramework.createMd('SHA256');
    const encoder = new util.TextEncoder();
    const bytes = encoder.encodeInto(`${salt}:${pin}`);
    digest.updateSync({ data: bytes });
    const result = digest.digestSync();
    return PinSecurity.toHex(result.data);
  }

  private static async hashLegacyAsync(pin: string, salt: string): Promise<string> {
    const digest = cryptoFramework.createMd('SHA256');
    const encoder = new util.TextEncoder();
    const bytes = encoder.encodeInto(`${salt}:${pin}`);
    await digest.update({ data: bytes });
    const result = await digest.digest();
    return PinSecurity.toHex(result.data);
  }

  private static equal(actual: string, expected: string): boolean {
    if (actual.length !== expected.length) {
      return false;
    }
    let difference = 0;
    for (let index = 0; index < actual.length; index++) {
      difference |= actual.charCodeAt(index) ^ expected.charCodeAt(index);
    }
    return difference === 0;
  }

  private static toHex(data: Uint8Array): string {
    let value = '';
    for (let index = 0; index < data.length; index++) {
      value += data[index].toString(16).padStart(2, '0');
    }
    return value;
  }
}
