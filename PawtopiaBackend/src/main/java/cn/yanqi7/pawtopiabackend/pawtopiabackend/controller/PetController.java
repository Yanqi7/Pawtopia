package cn.yanqi7.pawtopiabackend.pawtopiabackend.controller;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Pet;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.security.SecurityUtil;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.PetService;
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

    @GetMapping
    public ResponseEntity<List<Pet>> getAllPets() {
        return new ResponseEntity<>(petService.getAllPets(), HttpStatus.OK);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Pet> getPetById(@PathVariable Long id) {
        Optional<Pet> pet = petService.getPetById(id);
        return pet.map(value -> new ResponseEntity<>(value, HttpStatus.OK))
                .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
    }

    @GetMapping("/owner/{ownerId}")
    public ResponseEntity<List<Pet>> getPetsByOwnerId(@PathVariable Long ownerId) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        if (!SecurityUtil.isAdmin() && !currentUserId.equals(ownerId)) {
            return new ResponseEntity<>(HttpStatus.FORBIDDEN);
        }
        return new ResponseEntity<>(petService.getPetsByOwnerId(ownerId), HttpStatus.OK);
    }

    @GetMapping("/species/{species}")
    public ResponseEntity<List<Pet>> getPetsBySpecies(@PathVariable String species) {
        return new ResponseEntity<>(petService.getPetsBySpecies(species), HttpStatus.OK);
    }

    @GetMapping("/owner/{ownerId}/species/{species}")
    public ResponseEntity<List<Pet>> getPetsByOwnerIdAndSpecies(@PathVariable Long ownerId, @PathVariable String species) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        if (!SecurityUtil.isAdmin() && !currentUserId.equals(ownerId)) {
            return new ResponseEntity<>(HttpStatus.FORBIDDEN);
        }
        return new ResponseEntity<>(petService.getPetsByOwnerIdAndSpecies(ownerId, species), HttpStatus.OK);
    }

    @PostMapping
    public ResponseEntity<Pet> createPet(@RequestBody Pet pet) {
        Long currentUserId = SecurityUtil.userId();
        if (currentUserId == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }
        pet.setOwnerId(SecurityUtil.isAdmin() && pet.getOwnerId() != null ? pet.getOwnerId() : currentUserId);
        return new ResponseEntity<>(petService.createPet(pet), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Pet> updatePet(@PathVariable Long id, @RequestBody Pet petDetails) {
        Optional<Pet> existingPet = petService.getPetById(id);
        if (existingPet.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        if (!SecurityUtil.isAdmin() && !SecurityUtil.isSelf(existingPet.get().getOwnerId())) {
            return new ResponseEntity<>(HttpStatus.FORBIDDEN);
        }
        if (!SecurityUtil.isAdmin()) {
            petDetails.setOwnerId(existingPet.get().getOwnerId());
        }
        try {
            return new ResponseEntity<>(petService.updatePet(id, petDetails), HttpStatus.OK);
        } catch (RuntimeException e) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<HttpStatus> deletePet(@PathVariable Long id) {
        Optional<Pet> existingPet = petService.getPetById(id);
        if (existingPet.isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        if (!SecurityUtil.isAdmin() && !SecurityUtil.isSelf(existingPet.get().getOwnerId())) {
            return new ResponseEntity<>(HttpStatus.FORBIDDEN);
        }
        petService.deletePet(id);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }
}
