export class TimeUtils {
  public static dayKey(epochMs: number): string {
    const date = new Date(epochMs);
    return `${date.getFullYear()}-${TimeUtils.pad2(date.getMonth() + 1)}-${TimeUtils.pad2(date.getDate())}`;
  }

  public static pad2(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  public static formatClock(hour: number, minute: number): string {
    return `${TimeUtils.pad2(hour)}:${TimeUtils.pad2(minute)}`;
  }

  public static parseClock(value: string): [number, number] {
    const parts = value.split(':');
    const hour = Number(parts[0]);
    const minute = Number(parts[1]);
    return [
      Number.isFinite(hour) ? hour : 0,
      Number.isFinite(minute) ? minute : 0
    ];
  }

  public static formatDateLabel(epochMs: number): string {
    const date = new Date(epochMs);
    return `${TimeUtils.pad2(date.getMonth() + 1)}月${TimeUtils.pad2(date.getDate())}日`;
  }

  public static startOfDay(epochMs: number): number {
    const date = new Date(epochMs);
    date.setHours(0, 0, 0, 0);
    return date.getTime();
  }

  public static isValidClock(value: string): boolean {
    const matched = /^(\d{2}):(\d{2})$/.exec(value);
    if (matched === null) {
      return false;
    }
    const hour = Number(matched[1]);
    const minute = Number(matched[2]);
    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }

  /**
   * downtime 格式 "HH:mm-HH:mm"。结束小于开始时视为跨午夜，与安卓 TimeUtils 一致。
   */
  public static isCurrentlyInDowntime(downtime: string): boolean {
    if (downtime.length === 0) {
      return false;
    }
    const parts = downtime.split('-');
    if (parts.length !== 2) {
      return false;
    }
    if (!TimeUtils.isValidClock(parts[0]) || !TimeUtils.isValidClock(parts[1])) {
      return false;
    }
    const now = new Date();
    const nowTotal = now.getHours() * 60 + now.getMinutes();
    const start = TimeUtils.parseClock(parts[0]);
    const end = TimeUtils.parseClock(parts[1]);
    const startTotal = start[0] * 60 + start[1];
    const endTotal = end[0] * 60 + end[1];
    if (startTotal === endTotal) {
      return false;
    }
    if (startTotal < endTotal) {
      return nowTotal >= startTotal && nowTotal <= endTotal;
    }
    return nowTotal >= startTotal || nowTotal <= endTotal;
  }

  public static guardStatus(authorized: boolean, downtime: string, managedCount: number): string {
    if (!authorized || managedCount <= 0) {
      return '';
    }
    if (TimeUtils.isCurrentlyInDowntime(downtime)) {
      return '停用时间中';
    }
    return '守护中';
  }
}
