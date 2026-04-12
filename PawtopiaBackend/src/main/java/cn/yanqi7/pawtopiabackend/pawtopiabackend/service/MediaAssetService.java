package cn.yanqi7.pawtopiabackend.pawtopiabackend.service;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.config.StorageProperties;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.MediaAsset;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.MediaAssetRepository;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URLConnection;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR;

@Service
public class MediaAssetService {
    private static final List<String> ALLOWED_IMAGE_TYPES = List.of(
            "image/jpeg", "image/png", "image/gif", "image/webp", "image/bmp"
    );

    private final MediaAssetRepository mediaAssetRepository;
    private final StorageProperties storageProperties;
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build();

    public MediaAssetService(MediaAssetRepository mediaAssetRepository, StorageProperties storageProperties) {
        this.mediaAssetRepository = mediaAssetRepository;
        this.storageProperties = storageProperties;
    }

    public List<MediaAsset> listAll() {
        return mediaAssetRepository.findAll();
    }

    public Optional<MediaAsset> getById(Long id) {
        return mediaAssetRepository.findById(id);
    }

    public MediaAsset saveUpload(MultipartFile file, String name, Long uploadedBy) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(BAD_REQUEST, "上传文件不能为空");
        }
        String contentType = normalizeContentType(file.getContentType(), file.getOriginalFilename());
        validateImageType(contentType);

        String originalName = StringUtils.cleanPath(file.getOriginalFilename() == null ? "file" : file.getOriginalFilename());
        String extension = getExtension(originalName, contentType);
        String storedFileName = UUID.randomUUID() + extension;
        Path targetPath = resolveTargetPath(storedFileName);

        try {
            Files.createDirectories(targetPath.getParent());
            try (InputStream inputStream = file.getInputStream()) {
                Files.copy(inputStream, targetPath, StandardCopyOption.REPLACE_EXISTING);
            }
            MediaAsset asset = new MediaAsset();
            asset.setName(resolveName(name, originalName));
            asset.setOriginalName(originalName);
            asset.setUrl(buildPublicUrl(storedFileName));
            asset.setStoragePath(targetPath.toString());
            asset.setContentType(contentType);
            asset.setFileSize(file.getSize());
            asset.setSourceType(MediaAsset.SourceType.UPLOAD);
            asset.setUploadedBy(uploadedBy);
            return mediaAssetRepository.save(asset);
        } catch (IOException e) {
            throw new ResponseStatusException(INTERNAL_SERVER_ERROR, "保存上传文件失败", e);
        }
    }

    public MediaAsset fetchRemoteImage(String remoteUrl, String name, Long uploadedBy) {
        if (!StringUtils.hasText(remoteUrl)) {
            throw new ResponseStatusException(BAD_REQUEST, "远程图片地址不能为空");
        }
        URI uri;
        try {
            uri = URI.create(remoteUrl.trim());
        } catch (Exception ex) {
            throw new ResponseStatusException(BAD_REQUEST, "远程图片地址格式不正确", ex);
        }
        if (uri.getScheme() == null || (!"http".equalsIgnoreCase(uri.getScheme()) && !"https".equalsIgnoreCase(uri.getScheme()))) {
            throw new ResponseStatusException(BAD_REQUEST, "仅支持 http/https 图片地址");
        }

        HttpRequest request = HttpRequest.newBuilder(uri)
                .timeout(Duration.ofSeconds(20))
                .GET()
                .build();

        try {
            HttpResponse<byte[]> response = httpClient.send(request, HttpResponse.BodyHandlers.ofByteArray());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new ResponseStatusException(BAD_REQUEST, "远程图片获取失败，状态码: " + response.statusCode());
            }
            String contentType = normalizeContentType(response.headers().firstValue("Content-Type").orElse(null), remoteUrl);
            validateImageType(contentType);
            String extension = getExtension(remoteUrl, contentType);
            String storedFileName = UUID.randomUUID() + extension;
            Path targetPath = resolveTargetPath(storedFileName);
            Files.createDirectories(targetPath.getParent());
            Files.write(targetPath, response.body());

            MediaAsset asset = new MediaAsset();
            asset.setName(resolveName(name, extractFileName(remoteUrl)));
            asset.setOriginalName(extractFileName(remoteUrl));
            asset.setUrl(buildPublicUrl(storedFileName));
            asset.setStoragePath(targetPath.toString());
            asset.setContentType(contentType);
            asset.setFileSize((long) response.body().length);
            asset.setSourceType(MediaAsset.SourceType.REMOTE_FETCH);
            asset.setSourceUrl(remoteUrl.trim());
            asset.setUploadedBy(uploadedBy);
            return mediaAssetRepository.save(asset);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ResponseStatusException(INTERNAL_SERVER_ERROR, "远程图片保存失败", e);
        } catch (IOException e) {
            throw new ResponseStatusException(INTERNAL_SERVER_ERROR, "远程图片保存失败", e);
        }
    }

    private void validateImageType(String contentType) {
        if (!ALLOWED_IMAGE_TYPES.contains(contentType.toLowerCase(Locale.ROOT))) {
            throw new ResponseStatusException(BAD_REQUEST, "仅支持常见图片格式上传");
        }
    }

    private String normalizeContentType(String contentType, String fileName) {
        String resolved = contentType;
        if (!StringUtils.hasText(resolved) || "application/octet-stream".equalsIgnoreCase(resolved)) {
            resolved = URLConnection.guessContentTypeFromName(fileName);
        }
        if (!StringUtils.hasText(resolved)) {
            String extension = getRawExtension(fileName);
            resolved = switch (extension.toLowerCase(Locale.ROOT)) {
                case "jpg", "jpeg" -> "image/jpeg";
                case "png" -> "image/png";
                case "gif" -> "image/gif";
                case "webp" -> "image/webp";
                case "bmp" -> "image/bmp";
                default -> "application/octet-stream";
            };
        }
        return resolved;
    }

    private String resolveName(String preferredName, String fallbackName) {
        if (StringUtils.hasText(preferredName)) {
            return preferredName.trim();
        }
        return StringUtils.hasText(fallbackName) ? fallbackName : "image";
    }

    private Path resolveTargetPath(String storedFileName) {
        return Paths.get(storageProperties.getUploadDir()).toAbsolutePath().normalize().resolve(storedFileName);
    }

    private String buildPublicUrl(String storedFileName) {
        String publicBasePath = storageProperties.getPublicBasePath();
        if (!StringUtils.hasText(publicBasePath)) {
            publicBasePath = "/uploads";
        }
        if (!publicBasePath.startsWith("/")) {
            publicBasePath = "/" + publicBasePath;
        }
        return publicBasePath + "/" + storedFileName;
    }

    private String getExtension(String fileName, String contentType) {
        String rawExtension = getRawExtension(fileName);
        if (StringUtils.hasText(rawExtension)) {
            return "." + rawExtension.toLowerCase(Locale.ROOT);
        }
        return switch (contentType.toLowerCase(Locale.ROOT)) {
            case "image/jpeg" -> ".jpg";
            case "image/png" -> ".png";
            case "image/gif" -> ".gif";
            case "image/webp" -> ".webp";
            case "image/bmp" -> ".bmp";
            default -> "";
        };
    }

    private String getRawExtension(String fileName) {
        if (!StringUtils.hasText(fileName)) {
            return "";
        }
        String cleanName = fileName;
        int queryIndex = cleanName.indexOf('?');
        if (queryIndex >= 0) {
            cleanName = cleanName.substring(0, queryIndex);
        }
        int dotIndex = cleanName.lastIndexOf('.');
        if (dotIndex < 0 || dotIndex == cleanName.length() - 1) {
            return "";
        }
        return cleanName.substring(dotIndex + 1);
    }

    private String extractFileName(String source) {
        if (!StringUtils.hasText(source)) {
            return "remote-image";
        }
        String normalized = source;
        int slash = normalized.lastIndexOf('/');
        if (slash >= 0 && slash < normalized.length() - 1) {
            normalized = normalized.substring(slash + 1);
        }
        int query = normalized.indexOf('?');
        if (query >= 0) {
            normalized = normalized.substring(0, query);
        }
        return StringUtils.hasText(normalized) ? normalized : "remote-image";
    }
}
