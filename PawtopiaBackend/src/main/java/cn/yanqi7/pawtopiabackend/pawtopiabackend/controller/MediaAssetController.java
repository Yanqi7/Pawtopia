package cn.yanqi7.pawtopiabackend.pawtopiabackend.controller;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.dto.MediaAssetDtos;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.MediaAsset;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.security.SecurityUtil;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.MediaAssetService;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/admin/media-assets")
@CrossOrigin(origins = "*")
public class MediaAssetController {
    private final MediaAssetService mediaAssetService;

    public MediaAssetController(MediaAssetService mediaAssetService) {
        this.mediaAssetService = mediaAssetService;
    }

    @GetMapping
    public ResponseEntity<List<MediaAsset>> list() {
        ensureAdmin();
        return new ResponseEntity<>(mediaAssetService.listAll(), HttpStatus.OK);
    }

    @GetMapping("/{id}")
    public ResponseEntity<MediaAsset> get(@PathVariable Long id) {
        ensureAdmin();
        return mediaAssetService.getById(id)
                .map(asset -> new ResponseEntity<>(asset, HttpStatus.OK))
                .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
    }

    @PostMapping(value = "/upload", consumes = {"multipart/form-data"})
    public ResponseEntity<MediaAsset> upload(@RequestPart("file") MultipartFile file) {
        ensureAdmin();
        MediaAsset asset = mediaAssetService.saveUpload(file, null, SecurityUtil.userId());
        return new ResponseEntity<>(asset, HttpStatus.CREATED);
    }

    @PostMapping("/fetch")
    public ResponseEntity<MediaAsset> fetchRemote(@RequestBody MediaAssetDtos.RemoteFetchRequest request) {
        ensureAdmin();
        MediaAsset asset = mediaAssetService.fetchRemoteImage(request.getUrl(), request.getName(), SecurityUtil.userId());
        return new ResponseEntity<>(asset, HttpStatus.CREATED);
    }

    private void ensureAdmin() {
        if (!SecurityUtil.isAdmin()) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "Admin access required");
        }
    }
}
