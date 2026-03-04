package cn.yanqi7.pawtopiabackend.pawtopiabackend.service;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Pet;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.PetRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class PetService {
    
    @Autowired
    private PetRepository petRepository;
    
    public List<Pet> getAllPets() {
        return petRepository.findAll();
    }
    
    public Optional<Pet> getPetById(Long id) {
        return petRepository.findById(id);
    }
    
    public List<Pet> getPetsByOwnerId(Long ownerId) {
        return petRepository.findByOwnerId(ownerId);
    }
    
    public List<Pet> getPetsBySpecies(String species) {
        return petRepository.findBySpecies(species);
    }
    
    public List<Pet> getPetsByOwnerIdAndSpecies(Long ownerId, String species) {
        return petRepository.findByOwnerIdAndSpecies(ownerId, species);
    }
    
    public Pet createPet(Pet pet) {
        return petRepository.save(pet);
    }
    
    public Pet updatePet(Long id, Pet petDetails) {
        Pet pet = petRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Pet not found with id: " + id));
        
        pet.setName(petDetails.getName());
        pet.setSpecies(petDetails.getSpecies());
        pet.setBreed(petDetails.getBreed());
        pet.setColor(petDetails.getColor());
        pet.setAge(petDetails.getAge());
        pet.setGender(petDetails.getGender());
        pet.setSize(petDetails.getSize());
        pet.setDescription(petDetails.getDescription());
        pet.setBirthDate(petDetails.getBirthDate());
        pet.setOwnerId(petDetails.getOwnerId());
        
        return petRepository.save(pet);
    }
    
    public void deletePet(Long id) {
        petRepository.deleteById(id);
    }
}