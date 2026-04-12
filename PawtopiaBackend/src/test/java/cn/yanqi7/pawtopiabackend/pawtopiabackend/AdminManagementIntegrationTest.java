package cn.yanqi7.pawtopiabackend.pawtopiabackend;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.AdoptionRequest;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Pet;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Product;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.User;
import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AdminManagementIntegrationTest extends AbstractIntegrationTest {

    @Test
    void adminShouldManageProductsPetsAndAdoptions() throws Exception {
        User admin = createUser("admin_manage", User.Role.ADMIN);
        User seller = createUser("admin_seller", User.Role.SELLER);
        User owner = createUser("admin_owner", User.Role.USER);
        User requester = createUser("admin_requester", User.Role.USER);

        Product product = createProduct(seller, "旧商品", 5, "29.90");
        Pet pet = createPet(owner, "待领养宠物");

        JsonNode createdProduct = readJson(mockMvc.perform(post("/api/admin/products")
                        .header(headerName(), authorization(admin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json(Map.of(
                                "name", "管理员新商品",
                                "description", "后台创建",
                                "price", 88.5,
                                "image", "/uploads/admin-product.png",
                                "stockQuantity", 12,
                                "sellerId", seller.getId(),
                                "category", "TOY"
                        ))))
                .andExpect(status().isCreated())
                .andReturn());
        assertEquals("管理员新商品", createdProduct.path("name").asText());

        mockMvc.perform(put("/api/admin/products/{id}", product.getId())
                        .header(headerName(), authorization(admin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json(Map.of(
                                "name", "管理员改名商品",
                                "price", 39.9,
                                "stockQuantity", 9,
                                "category", "FOOD"
                        ))))
                .andExpect(status().isOk());
        assertEquals("管理员改名商品", productRepository.findById(product.getId()).orElseThrow().getName());

        JsonNode createdPet = readJson(mockMvc.perform(post("/api/admin/pets")
                        .header(headerName(), authorization(admin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json(Map.of(
                                "name", "管理员创建宠物",
                                "species", "猫",
                                "breed", "狸花",
                                "ownerId", owner.getId(),
                                "adoptionStatus", "AVAILABLE",
                                "adoptionCity", "南京",
                                "image", "/uploads/pet.png"
                        ))))
                .andExpect(status().isCreated())
                .andReturn());
        assertEquals("管理员创建宠物", createdPet.path("name").asText());

        JsonNode createdRequest = readJson(mockMvc.perform(post("/api/adoptions/pets/{petId}/requests", pet.getId())
                        .header(headerName(), authorization(requester))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json(Map.of("message", "请考虑我"))))
                .andExpect(status().isCreated())
                .andReturn());

        mockMvc.perform(put("/api/admin/pets/{id}", pet.getId())
                        .header(headerName(), authorization(admin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json(Map.of(
                                "name", "已暂停领养",
                                "species", "狗",
                                "breed", "柯基",
                                "ownerId", owner.getId(),
                                "adoptionStatus", "PAUSED",
                                "adoptionCity", "苏州"
                        ))))
                .andExpect(status().isOk());
        assertEquals(Pet.AdoptionStatus.PAUSED, petRepository.findById(pet.getId()).orElseThrow().getAdoptionStatus());

        mockMvc.perform(get("/api/admin/adoptions/requests/{id}", createdRequest.path("id").asLong())
                        .header(headerName(), authorization(admin)))
                .andExpect(status().isOk());

        mockMvc.perform(put("/api/admin/adoptions/requests/{id}/status/APPROVED", createdRequest.path("id").asLong())
                        .header(headerName(), authorization(admin)))
                .andExpect(status().isConflict());

        pet.setAdoptionStatus(Pet.AdoptionStatus.AVAILABLE);
        petRepository.save(pet);

        mockMvc.perform(put("/api/admin/adoptions/requests/{id}/status/APPROVED", createdRequest.path("id").asLong())
                        .header(headerName(), authorization(admin)))
                .andExpect(status().isOk());
        assertEquals(AdoptionRequest.Status.APPROVED,
                adoptionRequestRepository.findById(createdRequest.path("id").asLong()).orElseThrow().getStatus());

        mockMvc.perform(delete("/api/admin/products/{id}", product.getId())
                        .header(headerName(), authorization(admin)))
                .andExpect(status().isNoContent());

        Long createdPetId = createdPet.path("id").asLong();
        mockMvc.perform(delete("/api/admin/pets/{id}", createdPetId)
                        .header(headerName(), authorization(admin)))
                .andExpect(status().isNoContent());
    }

    @Test
    void mediaUploadShouldReturnReadablePublicUrl() throws Exception {
        User admin = createUser("admin_media", User.Role.ADMIN);
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "tiny.png",
                MediaType.IMAGE_PNG_VALUE,
                new byte[]{(byte) 0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a}
        );

        JsonNode asset = readJson(mockMvc.perform(multipart("/api/admin/media-assets/upload")
                        .file(file)
                        .header(headerName(), authorization(admin)))
                .andExpect(status().isCreated())
                .andReturn());

        String url = asset.path("url").asText();
        assertTrue(url.startsWith("/uploads/"));

        mockMvc.perform(get(url))
                .andExpect(status().isOk());
    }
}
