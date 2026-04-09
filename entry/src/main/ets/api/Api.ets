import { HttpClient, HttpError } from './HttpClient';
import { AppConfig } from '../app/AppConfig';
import { PreferencesStore } from '../store/PreferencesStore';
import { Comment, Order, OrderStatus, Page, Pet, Post, Product, User, UserRole, HealthRecord, AdoptionRequest, AdoptionRequestStatus } from '../model/Models';
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

export class Api {
  static async getBaseUrl(): Promise<string> {
    const baseUrl = await PreferencesStore.getString(AppConfig.PREF_KEY_BASE_URL, AppConfig.DEFAULT_BASE_URL);
    return baseUrl || AppConfig.DEFAULT_BASE_URL;
  }

  static async client(): Promise<HttpClient> {
    return new HttpClient(await Api.getBaseUrl(), SessionStore.getToken());
  }

  static async login(username: string, password: string): Promise<User> {
    try {
      const c = new HttpClient(await Api.getBaseUrl());
      const body: LoginRequestBody = { username, password };
      const res = await c.postJson<AuthResponseBody>('/api/auth/login', JSON.stringify(body));
      const role = (res.user.role ?? (res.user.username === 'user1' ? 'ADMIN' : 'USER')) as UserRole;
      await SessionStore.login(res.user, role, res.token);
      AppStatus.setBackendOnline(true);
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
      AppStatus.setBackendOnline(true);
      return res.user;
    } catch (e) {
      if (e instanceof HttpError && e.statusCode === 409) {
        throw new Error('用户名或邮箱已存在');
      }
      const msg = e instanceof Error ? e.message : '注册失败';
      throw new Error(msg || '注册失败');
    }
  }

  static async updateUser(userId: number, patch: UpdateUserBody): Promise<User> {
    const c = await Api.client();
    return await c.putJson<User>(`/api/users/${userId}`, JSON.stringify(patch));
  }

  static async getMyPets(ownerId: number): Promise<Pet[]> {
    try {
      const c = await Api.client();
      const res = await c.get<Pet[]>(`/api/pets/owner/${ownerId}`);
      AppStatus.setBackendOnline(true);
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
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async getAllPets(): Promise<Pet[]> {
    try {
      const c = await Api.client();
      const res = await c.get<Pet[]>('/api/pets');
      AppStatus.setBackendOnline(true);
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async getAdoptionListings(): Promise<Pet[]> {
    try {
      const c = await Api.client();
      const res = await c.get<Pet[]>('/api/adoptions/listings');
      AppStatus.setBackendOnline(true);
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async createAdoptionRequest(petId: number, body: CreateAdoptionRequestBody): Promise<AdoptionRequest> {
    try {
      const c = await Api.client();
      const res = await c.postJson<AdoptionRequest>(`/api/adoptions/pets/${petId}/requests`, JSON.stringify(body));
      AppStatus.setBackendOnline(true);
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        if (e.statusCode === 401) {
          throw new Error('请先登录后提交领养申请');
        }
        if (e.statusCode === 409) {
          throw new Error('你已提交过申请或该宠物暂不可申请');
        }
      }
      const msg = e instanceof Error ? e.message : '提交失败';
      throw new Error(msg);
    }
  }

  static async getAdoptionRequestsByPet(petId: number): Promise<AdoptionRequest[]> {
    try {
      const c = await Api.client();
      const res = await c.get<AdoptionRequest[]>(`/api/adoptions/pets/${petId}/requests`);
      AppStatus.setBackendOnline(true);
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
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async updateAdoptionRequestStatus(id: number, status: AdoptionRequestStatus): Promise<AdoptionRequest> {
    const c = await Api.client();
    return await c.put<AdoptionRequest>(`/api/adoptions/requests/${id}/status/${status}`);
  }

  static async cancelAdoptionRequest(id: number): Promise<AdoptionRequest> {
    const c = await Api.client();
    return await c.put<AdoptionRequest>(`/api/adoptions/requests/${id}/cancel`);
  }

  static async createPet(pet: Pet): Promise<Pet> {
    const c = await Api.client();
    return await c.postJson<Pet>('/api/pets', JSON.stringify(pet));
  }

  static async getPet(petId: number): Promise<Pet> {
    try {
      const c = await Api.client();
      const res = await c.get<Pet>(`/api/pets/${petId}`);
      AppStatus.setBackendOnline(true);
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async getHealthRecordsByPet(petId: number): Promise<HealthRecord[]> {
    try {
      const c = await Api.client();
      const res = await c.get<HealthRecord[]>(`/api/health-records/pet/${petId}`);
      AppStatus.setBackendOnline(true);
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
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async createHealthRecord(record: HealthRecord): Promise<HealthRecord> {
    const c = await Api.client();
    return await c.postJson<HealthRecord>('/api/health-records', JSON.stringify(record));
  }

  static async getPosts(page: number, size: number): Promise<Page<Post>> {
    try {
      const c = await Api.client();
      const res = await c.get<Page<Post>>('/api/posts', `page=${page}&size=${size}`);
      AppStatus.setBackendOnline(true);
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async getPost(postId: number): Promise<Post> {
    try {
      const c = await Api.client();
      const res = await c.get<Post>(`/api/posts/${postId}`);
      AppStatus.setBackendOnline(true);
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async createPost(post: Post): Promise<Post> {
    const c = await Api.client();
    return await c.postJson<Post>('/api/posts', JSON.stringify(post));
  }

  static async getUserPosts(userId: number): Promise<Post[]> {
    try {
      const c = await Api.client();
      const res = await c.get<Post[]>(`/api/posts/user/${userId}/all`);
      AppStatus.setBackendOnline(true);
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async likePost(postId: number): Promise<Post> {
    const c = await Api.client();
    return await c.post<Post>(`/api/posts/${postId}/like`);
  }

  static async getComments(postId: number, page: number, size: number): Promise<Page<Comment>> {
    try {
      const c = await Api.client();
      const res = await c.get<Page<Comment>>(`/api/comments/post/${postId}`, `page=${page}&size=${size}`);
      AppStatus.setBackendOnline(true);
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async getTopLevelComments(postId: number): Promise<Comment[]> {
    try {
      const c = await Api.client();
      const res = await c.get<Comment[]>(`/api/comments/post/${postId}/top`);
      AppStatus.setBackendOnline(true);
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async getRepliesByParent(parentId: number): Promise<Comment[]> {
    try {
      const c = await Api.client();
      const res = await c.get<Comment[]>(`/api/comments/parent/${parentId}`);
      AppStatus.setBackendOnline(true);
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async createComment(comment: Comment): Promise<Comment> {
    const c = await Api.client();
    return await c.postJson<Comment>('/api/comments', JSON.stringify(comment));
  }

  static async getProducts(page: number, size: number): Promise<Page<Product>> {
    try {
      const c = await Api.client();
      const res = await c.get<Page<Product>>('/api/products', `page=${page}&size=${size}&sortBy=id`);
      AppStatus.setBackendOnline(true);
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async getProduct(productId: number): Promise<Product> {
    try {
      const c = await Api.client();
      const res = await c.get<Product>(`/api/products/${productId}`);
      AppStatus.setBackendOnline(true);
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async searchProducts(name: string, page: number, size: number): Promise<Page<Product>> {
    try {
      const c = await Api.client();
      const res = await c.get<Page<Product>>('/api/products/search', `name=${encodeURIComponent(name)}&page=${page}&size=${size}`);
      AppStatus.setBackendOnline(true);
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        throw new Error(e.message);
      }
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async createOrder(order: Order): Promise<Order> {
    const c = await Api.client();
    return await c.postJson<Order>('/api/orders', JSON.stringify(order));
  }

  static async getMyOrders(userId: number): Promise<Order[]> {
    try {
      const c = await Api.client();
      const res = await c.get<Order[]>(`/api/orders/user/${userId}`);
      AppStatus.setBackendOnline(true);
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
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async getMyAdoptionRequests(): Promise<AdoptionRequest[]> {
    try {
      const c = await Api.client();
      const res = await c.get<AdoptionRequest[]>('/api/adoptions/requests/mine');
      AppStatus.setBackendOnline(true);
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
      AppStatus.setBackendOnline(false);
      throw new Error('当前无法连接服务，请稍后重试');
    }
  }

  static async updateOrderStatus(orderId: number, status: OrderStatus): Promise<Order> {
    const c = await Api.client();
    return await c.put<Order>(`/api/orders/${orderId}/status/${status}`);
  }

  static async probeBackend(): Promise<boolean> {
    try {
      const c = new HttpClient(await Api.getBaseUrl());
      await c.get<Page<Post>>('/api/posts', 'page=0&size=1');
      AppStatus.setBackendOnline(true);
      return true;
    } catch (e) {
      AppStatus.setBackendOnline(false);
      return false;
    }
  }
}
