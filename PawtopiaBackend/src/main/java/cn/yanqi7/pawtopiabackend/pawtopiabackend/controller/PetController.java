package cn.yanqi7.pawtopiabackend.pawtopiabackend.controller;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Pet;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.PetService;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.security.SecurityUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/pets")
@CrossOrigin(origins = "*")
public class PetController {
    
    @Autowired
    private PetService petService;
    
    // 获取所有宠物
    @GetMapping
    public ResponseEntity<List<Pet>> getAllPets() {
        List<Pet> pets = petService.getAllPets();
        return new ResponseEntity<>(pets, HttpStatus.OK);
    }
    
    // 根据ID获取宠物
    @GetMapping("/{id}")
    public ResponseEntity<Pet> getPetById(@PathVariable Long id) {
        Optional<Pet> pet = petService.getPetById(id);
        if (pet.isPresent()) {
            return new ResponseEntity<>(pet.get(), HttpStatus.OK);
        } else {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 根据主人ID获取宠物
    @GetMapping("/owner/{ownerId}")
    public ResponseEntity<List<Pet>> getPetsByOwnerId(@PathVariable Long ownerId) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        if (!SecurityUtil.isAdmin() && !currentUserId.equals(ownerId)) {
            return new ResponseEntity<>(HttpStatus.FORBIDDEN);
        }
        List<Pet> pets = petService.getPetsByOwnerId(ownerId);
        return new ResponseEntity<>(pets, HttpStatus.OK);
    }
    
    // 根据物种获取宠物
    @GetMapping("/species/{species}")
    public ResponseEntity<List<Pet>> getPetsBySpecies(@PathVariable String species) {
        List<Pet> pets = petService.getPetsBySpecies(species);
        return new ResponseEntity<>(pets, HttpStatus.OK);
    }
    
    // 根据主人ID和物种获取宠物
    @GetMapping("/owner/{ownerId}/species/{species}")
    public ResponseEntity<List<Pet>> getPetsByOwnerIdAndSpecies(@PathVariable Long ownerId, @PathVariable String species) {
        List<Pet> pets = petService.getPetsByOwnerIdAndSpecies(ownerId, species);
        return new ResponseEntity<>(pets, HttpStatus.OK);
    }
    
    // 创建新宠物
    @PostMapping
    public ResponseEntity<Pet> createPet(@RequestBody Pet pet) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        if (!SecurityUtil.isAdmin()) {
            pet.setOwnerId(currentUserId);
        }
        Pet createdPet = petService.createPet(pet);
        return new ResponseEntity<>(createdPet, HttpStatus.CREATED);
    }
    
    // 更新宠物信息
    @PutMapping("/{id}")
    public ResponseEntity<Pet> updatePet(@PathVariable Long id, @RequestBody Pet petDetails) {
        try {
            Pet updatedPet = petService.updatePet(id, petDetails);
            return new ResponseEntity<>(updatedPet, HttpStatus.OK);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
    
    // 删除宠物
    @DeleteMapping("/{id}")
    public ResponseEntity<HttpStatus> deletePet(@PathVariable Long id) {
        try {
            petService.deletePet(id);
            return new ResponseEntity<>(HttpStatus.NO_CONTENT);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }
}
