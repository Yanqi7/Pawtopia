package cn.yanqi7.pawtopiabackend.pawtopiabackend.dto;

import lombok.Data;

public class MediaAssetDtos {
    @Data
    public static class RemoteFetchRequest {
        private String url;
        private String name;
    }
}
