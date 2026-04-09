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
  return userId ? `宠友 #${userId}` : '宠友分享';
}

export function normalizeKeyword(value: string): string {
  return value.trim().toLowerCase();
}

export function adoptionStatusLabel(status?: string): string {
  if (status === 'ADOPTED') {
    return '已领养';
  }
  if (status === 'PAUSED') {
    return '暂缓开放';
  }
  return '可申请';
}

export function petGenderLabel(gender?: string): string {
  if (gender === 'FEMALE') {
    return '母';
  }
  if (gender === 'MALE') {
    return '公';
  }
  return '未知';
}

export function productCategoryLabel(category?: string): string {
  switch (category) {
    case 'FOOD':
      return '主粮零食';
    case 'TOY':
      return '玩具互动';
    case 'CLOTHES':
      return '服饰穿戴';
    case 'ACCESSORY':
      return '护理用品';
    case 'MEDICINE':
      return '健康护理';
    default:
      return '精选好物';
  }
}

export function adoptionRequestStatusLabel(status?: string): string {
  switch (status) {
    case 'APPROVED':
      return '已通过';
    case 'REJECTED':
      return '已拒绝';
    case 'CANCELLED':
      return '已撤回';
    default:
      return '待处理';
  }
}

export function healthRecordTypeLabel(type?: string): string {
  switch (type) {
    case 'VACCINATION':
      return '疫苗';
    case 'EXAMINATION':
      return '体检';
    case 'TREATMENT':
      return '治疗';
    case 'MEDICATION':
      return '用药';
    case 'GROOMING':
      return '护理';
    default:
      return '记录';
  }
}

export function shortDate(value?: string): string {
  if (!value) {
    return '最近更新';
  }
  return value.length >= 10 ? value.slice(0, 10) : value;
}
