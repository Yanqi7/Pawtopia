package cn.yanqi7.pawtopiabackend.pawtopiabackend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;
import java.nio.file.Paths;

@Configuration
public class WebConfig implements WebMvcConfigurer {
    private final StorageProperties storageProperties;

    public WebConfig(StorageProperties storageProperties) {
        this.storageProperties = storageProperties;
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        Path uploadPath = Paths.get(storageProperties.getUploadDir()).toAbsolutePath().normalize();
        String publicBasePath = normalizePublicBasePath(storageProperties.getPublicBasePath());
        registry.addResourceHandler(publicBasePath + "/**")
                .addResourceLocations(uploadPath.toUri().toString());
    }

    private String normalizePublicBasePath(String publicBasePath) {
        if (publicBasePath == null || publicBasePath.isBlank()) {
            return "/uploads";
        }
        return publicBasePath.startsWith("/") ? publicBasePath : "/" + publicBasePath;
    }
}
