import http from '@ohos.net.http';

interface JsonHeaders {
  'Content-Type': string;
  'Accept': string;
  Authorization?: string;
}

export class HttpError extends Error {
  statusCode: number;
  bodyText: string;

  constructor(statusCode: number, bodyText: string) {
    super(`HTTP ${statusCode}`);
    this.statusCode = statusCode;
    this.bodyText = bodyText;
  }
}

export class HttpClient {
  private readonly baseUrl: string;
  private readonly token: string;

  constructor(baseUrl: string, token: string = '') {
    this.baseUrl = baseUrl.replace(/\/+$/, '');
    this.token = token;
  }

  async get<T>(path: string, queryString: string = ''): Promise<T> {
    return this.request<T>(http.RequestMethod.GET, path, undefined, queryString);
  }

  async post<T>(path: string): Promise<T> {
    return this.request<T>(http.RequestMethod.POST, path);
  }

  async postJson<T>(path: string, jsonBody: string): Promise<T> {
    return this.request<T>(http.RequestMethod.POST, path, jsonBody, '');
  }

  async put<T>(path: string): Promise<T> {
    return this.request<T>(http.RequestMethod.PUT, path);
  }

  async putJson<T>(path: string, jsonBody: string): Promise<T> {
    return this.request<T>(http.RequestMethod.PUT, path, jsonBody, '');
  }

  async delete<T>(path: string): Promise<T> {
    return this.request<T>(http.RequestMethod.DELETE, path);
  }

  private buildUrl(path: string, queryString: string = ''): string {
    const normalizedPath = path.startsWith('/') ? path : `/${path}`;
    const url = `${this.baseUrl}${normalizedPath}`;
    const q = queryString.trim();
    if (!q) {
      return url;
    }
    return q.startsWith('?') ? `${url}${q}` : `${url}?${q}`;
  }

  private async request<T>(
    method: http.RequestMethod,
    path: string,
    extraData?: string,
    queryString: string = ''
  ): Promise<T> {
    const url = this.buildUrl(path, queryString);
    const httpRequest = http.createHttp();

    const header: JsonHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    if (this.token) {
      header.Authorization = `Bearer ${this.token}`;
    }

    const options: http.HttpRequestOptions = {
      method,
      header,
      extraData,
      connectTimeout: 15000,
      readTimeout: 30000,
      expectDataType: http.HttpDataType.STRING
    };

    return await new Promise<T>((resolve, reject) => {
      httpRequest.request(url, options, (err, data) => {
        try {
          if (err) {
            reject(new Error(err.message));
            return;
          }
          const statusCode = data?.responseCode ?? 0;
          const raw = typeof data?.result === 'string' ? data.result : '';
          if (statusCode < 200 || statusCode >= 300) {
            reject(new HttpError(statusCode, raw));
            return;
          }
          if (!raw) {
            resolve(undefined as T);
            return;
          }
          resolve(JSON.parse(raw) as T);
        } catch (e) {
          const msg = e instanceof Error ? e.message : '解析失败';
          reject(new Error(msg));
        } finally {
          httpRequest.destroy();
        }
      });
    });
  }
}
