import { buffer } from '@kit.ArkTS';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';

export interface PinCredential {
  salt: string;
  hash: string;
}

export class PinSecurity {
  public static isValidFormat(pin: string): boolean {
    return /^\d{6}$/.test(pin);
  }

  public static async createCredential(pin: string): Promise<PinCredential> {
    const randomData = cryptoFramework.createRandom().generateRandomSync(16).data;
    const salt = PinSecurity.toHex(randomData);
    return {
      salt: salt,
      hash: await PinSecurity.hash(pin, salt)
    };
  }

  public static async verify(pin: string, salt: string, expectedHash: string): Promise<boolean> {
    const actual = await PinSecurity.hash(pin, salt);
    if (actual.length !== expectedHash.length) {
      return false;
    }
    let difference = 0;
    for (let index = 0; index < actual.length; index++) {
      difference |= actual.charCodeAt(index) ^ expectedHash.charCodeAt(index);
    }
    return difference === 0;
  }

  private static async hash(pin: string, salt: string): Promise<string> {
    const digest = cryptoFramework.createMd('SHA256');
    const encoded = buffer.from(`${salt}:${pin}`, 'utf-8');
    const input = new Uint8Array(encoded.buffer, encoded.byteOffset, encoded.length);
    await digest.update({ data: input });
    const result = await digest.digest();
    return PinSecurity.toHex(result.data);
  }

  private static toHex(data: Uint8Array): string {
    let value = '';
    for (let index = 0; index < data.length; index++) {
      value += data[index].toString(16).padStart(2, '0');
    }
    return value;
  }
}
