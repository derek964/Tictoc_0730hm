import { buffer, util } from '@kit.ArkTS';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';

export interface PinCredential {
  salt: string;
  hash: string;
}

export class PinSecurity {
  public static readonly DEFAULT_PIN: string = '1234';

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
      hash: await PinSecurity.hashLegacy(pin, salt)
    };
  }

  public static async verify(pin: string, salt: string, expectedHash: string): Promise<boolean> {
    if (!PinSecurity.isValidFormat(pin) || !PinSecurity.isCompleteCredential(salt, expectedHash)) {
      return false;
    }
    const legacy = await PinSecurity.hashLegacy(pin, salt);
    if (PinSecurity.equal(legacy, expectedHash)) {
      return true;
    }
    const modern = await PinSecurity.hashModern(pin, salt);
    return PinSecurity.equal(modern, expectedHash);
  }

  private static async hashLegacy(pin: string, salt: string): Promise<string> {
    const digest = cryptoFramework.createMd('SHA256');
    const encoded = buffer.from(`${salt}:${pin}`, 'utf-8');
    const input = new Uint8Array(encoded.buffer, encoded.byteOffset, encoded.length);
    await digest.update({ data: input });
    const result = await digest.digest();
    return PinSecurity.toHex(result.data);
  }

  private static async hashModern(pin: string, salt: string): Promise<string> {
    const digest = cryptoFramework.createMd('SHA256');
    const encoder = new util.TextEncoder();
    const bytes = encoder.encodeInto(`${salt}:${pin}`);
    digest.updateSync({ data: bytes });
    const result = digest.digestSync();
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
