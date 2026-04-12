import { HttpClient, HttpError } from './HttpClient';
import { AppConfig } from '../app/AppConfig';
import { PreferencesStore } from '../store/PreferencesStore';
import {
  Comment,
  Order,
  OrderStatus,
  Page,
  Pet,
  Post,
  Product,
  ProductCategory,
  User,
  UserRole,
  HealthRecord,
  HealthRecordType,
  AdoptionRequest,
  AdoptionRequestStatus
} from '../model/Models';
import { AppStatus } from '../app/AppStatus';
import { SessionStore } from '../store/SessionStore';

interface CreateUserBody {
  username: string;
  password: string;
  email: string;
  nickname?: string;
  role?: UserRole;
}

interface UpdateUserBody {
  nickname?: string;
  phone?: string;
  password?: string;
}

interface ManagedUserBody {
  username: string;
  password: string;
  email: string;
  nickname?: string;
  phone?: string;
  role: UserRole;
}

interface LoginRequestBody {
  username: string;
  password: string;
}

interface AuthResponseBody {
  token: string;
  user: User;
}

interface CreateAdoptionRequestBody {
  message?: string;
  contactName?: string;
  contactPhone?: string;
}

const ORDER_STATUSES: OrderStatus[] = ['PENDING', 'PAID', 'SHIPPED', 'DELIVERED', 'CANCELLED'];

export class Api {
  static async getBaseUrl(): Promise<string> {
    const baseUrl = await PreferencesStore.getString(AppConfig.PREF_KEY_BASE_URL, AppConfig.DEFAULT_BASE_URL);
    return baseUrl || AppConfig.DEFAULT_BASE_URL;
  }

  static async client(): Promise<HttpClient> {
    return new HttpClient(await Api.getBaseUrl(), SessionStore.getToken());
  }

  private static offlineError(message: string = '当前无法连接服务，请稍后重试'): never {
    AppStatus.setBackendOnline(false);
    throw new Error(message);
  }

  private static markOnline(): void {
    AppStatus.setBackendOnline(true);
  }

  static async login(username: string, password: string): Promise<User> {
    try {
      const c = new HttpClient(await Api.getBaseUrl());
      const body: LoginRequestBody = { username, password };
      const res = await c.postJson<AuthResponseBody>('/api/auth/login', JSON.stringify(body));
      const role = (res.user.role ?? 'USER') as UserRole;
      await SessionStore.login(res.user, role, res.token);
      Api.markOnline();
      return res.user;
    } catch (e) {
      if (e instanceof HttpError && (e.statusCode === 401 || e.statusCode === 403 || e.statusCode === 404)) {
        throw new Error('用户名或密码错误');
      }
      const msg = e instanceof Error ? e.message : '登录失败';
      throw new Error(msg || '登录失败');
    }
  }

  static async register(username: string, password: string, email: string, nickname: string, role: UserRole): Promise<User> {
    try {
      const c = new HttpClient(await Api.getBaseUrl());
      const body: CreateUserBody = { username, password, email, nickname, role };
      const res = await c.postJson<AuthResponseBody>('/api/auth/register', JSON.stringify(body));
      const savedRole = (res.user.role ?? role) as UserRole;
      await PreferencesStore.setString(AppConfig.PREF_KEY_SESSION_ROLE, savedRole);
      await SessionStore.login(res.user, savedRole, res.token);
      Api.markOnline();
      return res.user;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 409) {
          throw new Error('用户名或邮箱已存在');
        }
        if (e.statusCode === 403) {
          throw new Error('当前仅开放普通用户注册，其他角色需走审核流程');
        }
      }
      const msg = e instanceof Error ? e.message : '注册失败';
      throw new Error(msg || '注册失败');
    }
  }

  static async updateUser(userId: number, patch: UpdateUserBody): Promise<User> {
    try {
      const c = await Api.client();
      const res = await c.putJson<User>(`/api/users/${userId}`, JSON.stringify(patch));
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 401) {
          throw new Error('请重新登录后修改资料');
        }
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限修改该资料');
        }
        if (e.statusCode === 409) {
          throw new Error('用户名或邮箱已存在');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getAllUsers(): Promise<User[]> {
    try {
      const c = await Api.client();
      const res = await c.get<User[]>('/api/users');
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限查看用户列表');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getUsersByRole(role: UserRole): Promise<User[]> {
    try {
      const c = await Api.client();
      const res = await c.get<User[]>(`/api/users/role/${role}`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 401) {
          throw new Error('请先登录后查看用户列表');
        }
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限查看该角色列表');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async createManagedUser(body: ManagedUserBody): Promise<User> {
    try {
      const c = await Api.client();
      const res = await c.postJson<User>('/api/users', JSON.stringify(body));
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限创建用户');
        }
        if (e.statusCode === 409) {
          throw new Error('用户名或邮箱已存在');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async deleteUser(userId: number): Promise<void> {
    try {
      const c = await Api.client();
      await c.delete<void>(`/api/users/${userId}`);
      Api.markOnline();
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限删除该用户');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async purgeAllContent(): Promise<void> {
    try {
      const c = await Api.client();
      await c.delete<void>('/api/admin/content');
      Api.markOnline();
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限清空平台内容');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getMyPets(ownerId: number): Promise<Pet[]> {
    try {
      const c = await Api.client();
      const res = await c.get<Pet[]>(`/api/pets/owner/${ownerId}`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 401) {
          throw new Error('请重新登录后查看宠物档案');
        }
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限查看这些宠物档案');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getAllPets(): Promise<Pet[]> {
    try {
      const c = await Api.client();
      const res = await c.get<Pet[]>('/api/pets');
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async createPet(pet: Pet): Promise<Pet> {
    try {
      const c = await Api.client();
      const res = await c.postJson<Pet>('/api/pets', JSON.stringify(pet));
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 401) {
          throw new Error('请先登录后再创建宠物');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async updatePet(petId: number, pet: Pet): Promise<Pet> {
    try {
      const c = await Api.client();
      const res = await c.putJson<Pet>(`/api/pets/${petId}`, JSON.stringify(pet));
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限修改该宠物');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getPet(petId: number): Promise<Pet> {
    try {
      const c = await Api.client();
      const res = await c.get<Pet>(`/api/pets/${petId}`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getAdoptionListings(): Promise<Pet[]> {
    try {
      const c = await Api.client();
      const res = await c.get<Pet[]>('/api/adoptions/listings');
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async createAdoptionRequest(petId: number, body: CreateAdoptionRequestBody): Promise<AdoptionRequest> {
    try {
      const c = await Api.client();
      const res = await c.postJson<AdoptionRequest>(`/api/adoptions/pets/${petId}/requests`, JSON.stringify(body));
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 401) {
          throw new Error('请先登录后提交领养申请');
        }
        if (e.statusCode === 409) {
          throw new Error('你已提交过申请或该宠物暂不可申请');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getAdoptionRequestsByPet(petId: number): Promise<AdoptionRequest[]> {
    try {
      const c = await Api.client();
      const res = await c.get<AdoptionRequest[]>(`/api/adoptions/pets/${petId}/requests`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 401) {
          throw new Error('请先登录后查看领养申请');
        }
        if (e.statusCode === 403) {
          throw new Error('无权限查看该宠物的领养申请');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getOwnedAdoptionRequests(): Promise<AdoptionRequest[]> {
    try {
      const c = await Api.client();
      const res = await c.get<AdoptionRequest[]>('/api/adoptions/requests/owned');
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 401) {
          throw new Error('请先登录后查看待审申请');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getMyAdoptionRequests(): Promise<AdoptionRequest[]> {
    try {
      const c = await Api.client();
      const res = await c.get<AdoptionRequest[]>('/api/adoptions/requests/mine');
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 401) {
          throw new Error('请先登录后查看领养申请');
        }
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限查看领养申请');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async updateAdoptionRequestStatus(id: number, status: AdoptionRequestStatus): Promise<AdoptionRequest> {
    try {
      const c = await Api.client();
      const res = await c.put<AdoptionRequest>(`/api/adoptions/requests/${id}/status/${status}`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限审批该申请');
        }
        if (e.statusCode === 409) {
          throw new Error('申请状态已变化，请刷新后重试');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async cancelAdoptionRequest(id: number): Promise<AdoptionRequest> {
    try {
      const c = await Api.client();
      const res = await c.put<AdoptionRequest>(`/api/adoptions/requests/${id}/cancel`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 409) {
          throw new Error('该申请已处理，无法撤回');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getHealthRecordsByPet(petId: number): Promise<HealthRecord[]> {
    try {
      const c = await Api.client();
      const res = await c.get<HealthRecord[]>(`/api/health-records/pet/${petId}`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 401) {
          throw new Error('请重新登录后查看健康档案');
        }
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限查看该宠物健康档案');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getHealthRecordsByPetAndType(petId: number, recordType: HealthRecordType): Promise<HealthRecord[]> {
    try {
      const c = await Api.client();
      const res = await c.get<HealthRecord[]>(`/api/health-records/pet/${petId}/type/${recordType}`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getHealthRecordsByPetAndDateRange(petId: number, startDate: string, endDate: string): Promise<HealthRecord[]> {
    try {
      const c = await Api.client();
      const res = await c.get<HealthRecord[]>(`/api/health-records/pet/${petId}/date-range`, `startDate=${encodeURIComponent(startDate)}&endDate=${encodeURIComponent(endDate)}`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getUpcomingAppointments(startDate: string, endDate: string): Promise<HealthRecord[]> {
    try {
      const c = await Api.client();
      const res = await c.get<HealthRecord[]>('/api/health-records/upcoming-appointments', `startDate=${encodeURIComponent(startDate)}&endDate=${encodeURIComponent(endDate)}`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async createHealthRecord(record: HealthRecord): Promise<HealthRecord> {
    try {
      const c = await Api.client();
      const res = await c.postJson<HealthRecord>('/api/health-records', JSON.stringify(record));
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限维护该宠物健康记录');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getPosts(page: number, size: number): Promise<Page<Post>> {
    try {
      const c = await Api.client();
      const res = await c.get<Page<Post>>('/api/posts', `page=${page}&size=${size}`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getPost(postId: number): Promise<Post> {
    try {
      const c = await Api.client();
      const res = await c.get<Post>(`/api/posts/${postId}`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async createPost(post: Post): Promise<Post> {
    try {
      const c = await Api.client();
      const res = await c.postJson<Post>('/api/posts', JSON.stringify(post));
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 401) {
          throw new Error('请先登录后发布帖子');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async updatePost(postId: number, post: Post): Promise<Post> {
    try {
      const c = await Api.client();
      const res = await c.putJson<Post>(`/api/posts/${postId}`, JSON.stringify(post));
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限修改该帖子');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getUserPosts(userId: number): Promise<Post[]> {
    try {
      const c = await Api.client();
      const res = await c.get<Post[]>(`/api/posts/user/${userId}/all`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async deletePost(postId: number): Promise<void> {
    try {
      const c = await Api.client();
      await c.delete<void>(`/api/posts/${postId}`);
      Api.markOnline();
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限删除该帖子');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async likePost(postId: number): Promise<Post> {
    try {
      const c = await Api.client();
      const res = await c.post<Post>(`/api/posts/${postId}/like`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getComments(postId: number, page: number, size: number): Promise<Page<Comment>> {
    try {
      const c = await Api.client();
      const res = await c.get<Page<Comment>>(`/api/comments/post/${postId}`, `page=${page}&size=${size}`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getTopLevelComments(postId: number): Promise<Comment[]> {
    try {
      const c = await Api.client();
      const res = await c.get<Comment[]>(`/api/comments/post/${postId}/top`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getRepliesByParent(parentId: number): Promise<Comment[]> {
    try {
      const c = await Api.client();
      const res = await c.get<Comment[]>(`/api/comments/parent/${parentId}`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async createComment(comment: Comment): Promise<Comment> {
    try {
      const c = await Api.client();
      const res = await c.postJson<Comment>('/api/comments', JSON.stringify(comment));
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getProducts(page: number, size: number): Promise<Page<Product>> {
    try {
      const c = await Api.client();
      const res = await c.get<Page<Product>>('/api/products', `page=${page}&size=${size}&sortBy=id`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getProductsByCategory(category: ProductCategory, page: number, size: number): Promise<Page<Product>> {
    try {
      const c = await Api.client();
      const res = await c.get<Page<Product>>(`/api/products/category/${category}`, `page=${page}&size=${size}&sortBy=id`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getProductsBySeller(sellerId: number, page: number = 0, size: number = 40): Promise<Page<Product>> {
    try {
      const c = await Api.client();
      const res = await c.get<Page<Product>>(`/api/products/seller/${sellerId}`, `page=${page}&size=${size}&sortBy=id`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限查看该卖家商品');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async createProduct(product: Product): Promise<Product> {
    try {
      const c = await Api.client();
      const res = await c.postJson<Product>('/api/products', JSON.stringify(product));
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限创建商品');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async updateProduct(productId: number, product: Product): Promise<Product> {
    try {
      const c = await Api.client();
      const res = await c.putJson<Product>(`/api/products/${productId}`, JSON.stringify(product));
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限修改该商品');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async deleteProduct(productId: number): Promise<void> {
    try {
      const c = await Api.client();
      await c.delete<void>(`/api/products/${productId}`);
      Api.markOnline();
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限删除该商品');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getProduct(productId: number): Promise<Product> {
    try {
      const c = await Api.client();
      const res = await c.get<Product>(`/api/products/${productId}`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async searchProducts(name: string, page: number, size: number): Promise<Page<Product>> {
    try {
      const c = await Api.client();
      const res = await c.get<Page<Product>>('/api/products/search', `name=${encodeURIComponent(name)}&page=${page}&size=${size}`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async createOrder(order: Order): Promise<Order> {
    try {
      const c = await Api.client();
      const res = await c.postJson<Order>('/api/orders', JSON.stringify(order));
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 400) {
          throw new Error('订单信息不完整，请检查商品数量与收货信息');
        }
        if (e.statusCode === 401) {
          throw new Error('请先登录后再提交订单');
        }
        if (e.statusCode === 409) {
          throw new Error('部分商品库存或状态已变化，请返回购物车后重试');
        }
        throw new Error(e.message);
      }
      return Api.offlineError('当前无法连接服务，暂时不能提交订单');
    }
  }

  static async getMyOrders(userId: number, status?: OrderStatus | 'ALL'): Promise<Order[]> {
    try {
      const c = await Api.client();
      const path = status && status !== 'ALL' ? `/api/orders/user/${userId}/status/${status}` : `/api/orders/user/${userId}`;
      const res = await c.get<Order[]>(path);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 401) {
          throw new Error('请先登录后查看订单');
        }
        if (e.statusCode === 403) {
          throw new Error('无权限查看该用户订单');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getSellerOrders(sellerId: number, status?: OrderStatus | 'ALL'): Promise<Order[]> {
    try {
      const c = await Api.client();
      const path = status && status !== 'ALL' ? `/api/orders/seller/${sellerId}/status/${status}` : `/api/orders/seller/${sellerId}`;
      const res = await c.get<Order[]>(path);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限查看卖家订单');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async getAdminOrders(status?: OrderStatus | 'ALL'): Promise<Order[]> {
    try {
      const c = await Api.client();
      if (status && status !== 'ALL') {
        const res = await c.get<Order[]>(`/api/orders/status/${status}`);
        Api.markOnline();
        return res;
      }
      const groups = await Promise.all(ORDER_STATUSES.map((item: OrderStatus) => c.get<Order[]>(`/api/orders/status/${item}`)));
      const orderMap = new Map<number, Order>();
      groups.forEach((items: Order[]) => {
        items.forEach((order: Order) => {
          if (order.id) {
            orderMap.set(order.id, order);
          }
        });
      });
      Api.markOnline();
      return Array.from(orderMap.values());
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限查看系统订单');
        }
        throw new Error(e.message);
      }
      return Api.offlineError();
    }
  }

  static async updateOrderStatus(orderId: number, status: OrderStatus): Promise<Order> {
    try {
      const c = await Api.client();
      const res = await c.put<Order>(`/api/orders/${orderId}/status/${status}`);
      Api.markOnline();
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 401) {
          throw new Error('请先登录后再操作订单');
        }
        if (e.statusCode === 403) {
          throw new Error('当前账号无权限操作该订单');
        }
        if (e.statusCode === 409) {
          throw new Error('订单状态已变化，请刷新后重试');
        }
        throw new Error(e.message);
      }
      return Api.offlineError('当前无法连接服务，暂时不能更新订单');
    }
  }

  static async probeBackend(): Promise<boolean> {
    try {
      const c = new HttpClient(await Api.getBaseUrl());
      await c.get<Page<Post>>('/api/posts', 'page=0&size=1');
      Api.markOnline();
      return true;
    } catch (e) {
      AppStatus.setBackendOnline(false);
      return false;
    }
  }
}
