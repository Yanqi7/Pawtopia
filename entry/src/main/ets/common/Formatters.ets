export function relativeTime(value?: string): string {
  if (!value) {
    return '刚刚';
  }
  const date = new Date(value);
  const time = date.getTime();
  if (Number.isNaN(time)) {
    return value;
  }
  const diff = Date.now() - time;
  if (diff < 60 * 1000) {
    return '刚刚';
  }
  if (diff < 60 * 60 * 1000) {
    return `${Math.max(1, Math.floor(diff / (60 * 1000)))} 分钟前`;
  }
  if (diff < 24 * 60 * 60 * 1000) {
    return `${Math.max(1, Math.floor(diff / (60 * 60 * 1000)))} 小时前`;
  }
  if (diff < 30 * 24 * 60 * 60 * 1000) {
    return `${Math.max(1, Math.floor(diff / (24 * 60 * 60 * 1000)))} 天前`;
  }
  const year = String(date.getFullYear());
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export function postAuthorLabel(userId?: number): string {
  return userId ? `作者 #${userId}` : '宠友分享';
}

export function normalizeKeyword(value: string): string {
  return value.trim().toLowerCase();
}
