package cn.yanqi7.pawtopiabackend.pawtopiabackend.repository;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Pet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PetRepository extends JpaRepository<Pet, Long> {
    List<Pet> findByOwnerId(Long ownerId);
    List<Pet> findBySpecies(String species);
    List<Pet> findByOwnerIdAndSpecies(Long ownerId, String species);
    List<Pet> findByAdoptionStatus(Pet.AdoptionStatus adoptionStatus);
}
