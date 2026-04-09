export type UserRole = 'USER' | 'ADMIN' | 'PET_SHOP' | 'PET_HOSPITAL' | 'SELLER';
export type UserGender = 'MALE' | 'FEMALE' | 'OTHER';
export type PetGender = 'MALE' | 'FEMALE';
export type HealthRecordType = 'VACCINATION' | 'EXAMINATION' | 'TREATMENT' | 'MEDICATION' | 'GROOMING';
export type ProductCategory = 'FOOD' | 'TOY' | 'CLOTHES' | 'ACCESSORY' | 'MEDICINE' | 'OTHER';
export type OrderStatus = 'PENDING' | 'PAID' | 'SHIPPED' | 'DELIVERED' | 'CANCELLED';

export interface User {
  id?: number;
  username: string;
  password?: string;
  email: string;
  nickname?: string;
  avatar?: string;
  age?: number;
  gender?: UserGender;
  phone?: string;
  role?: UserRole;
  createdAt?: string;
  updatedAt?: string;
}

export interface Pet {
  id?: number;
  name: string;
  species: string;
  breed?: string;
  color?: string;
  age?: number;
  gender?: PetGender;
  size?: string;
  description?: string;
  image?: string;
  adoptionStatus?: 'AVAILABLE' | 'PAUSED' | 'ADOPTED';
  adoptionCity?: string;
  adoptionNote?: string;
  birthDate?: string;
  ownerId: number;
  createdAt?: string;
  updatedAt?: string;
}

export interface HealthRecord {
  id?: number;
  petId: number;
  recordType: HealthRecordType;
  title?: string;
  description?: string;
  recordDate: string;
  nextDueDate?: string;
  veterinarian?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface Product {
  id?: number;
  name: string;
  description?: string;
  price: string;
  image?: string;
  stockQuantity: number;
  category: ProductCategory;
  createdAt?: string;
  updatedAt?: string;
}

export interface Order {
  id?: number;
  userId: number;
  productIds: string;
  quantities: string;
  totalAmount: string;
  status: OrderStatus;
  shippingAddress?: string;
  contactPhone?: string;
  contactName?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface Post {
  id?: number;
  title: string;
  content: string;
  userId: number;
  petId?: number;
  imageUrls?: string;
  viewCount?: number;
  likeCount?: number;
  commentCount?: number;
  createdAt?: string;
  updatedAt?: string;
}

export interface Comment {
  id?: number;
  postId: number;
  userId: number;
  parentId?: number;
  content: string;
  likeCount?: number;
  createdAt?: string;
  updatedAt?: string;
}

export type AdoptionRequestStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'CANCELLED';

export interface AdoptionRequest {
  id?: number;
  petId: number;
  ownerId: number;
  requesterId: number;
  status: AdoptionRequestStatus;
  message?: string;
  contactName?: string;
  contactPhone?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface PetMessage {
  id?: number;
  petId: number;
  authorName: string;
  content: string;
  createdAt?: string;
}

export interface Page<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
  first: boolean;
  last: boolean;
  empty: boolean;
}
