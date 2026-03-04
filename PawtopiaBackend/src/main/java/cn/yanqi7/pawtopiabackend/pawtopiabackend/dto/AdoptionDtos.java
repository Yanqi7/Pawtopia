package cn.yanqi7.pawtopiabackend.pawtopiabackend.dto;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.AdoptionRequest;

public class AdoptionDtos {
    public static class CreateRequestBody {
        private String message;
        private String contactName;
        private String contactPhone;

        public String getMessage() {
            return message;
        }

        public void setMessage(String message) {
            this.message = message;
        }

        public String getContactName() {
            return contactName;
        }

        public void setContactName(String contactName) {
            this.contactName = contactName;
        }

        public String getContactPhone() {
            return contactPhone;
        }

        public void setContactPhone(String contactPhone) {
            this.contactPhone = contactPhone;
        }
    }

    public static class UpdateStatusBody {
        private AdoptionRequest.Status status;

        public AdoptionRequest.Status getStatus() {
            return status;
        }

        public void setStatus(AdoptionRequest.Status status) {
            this.status = status;
        }
    }
}

