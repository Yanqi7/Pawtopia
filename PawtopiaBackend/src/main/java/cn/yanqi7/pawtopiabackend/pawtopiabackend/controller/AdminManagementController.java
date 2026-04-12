package cn.yanqi7.pawtopiabackend.pawtopiabackend.controller;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.AdoptionRequest;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Pet;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.Product;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.security.SecurityUtil;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.AdoptionService;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.PetService;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.ProductService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*")
public class AdminManagementController {
    private final ProductService productService;
    private final PetService petService;
    private final AdoptionService adoptionService;

    public AdminManagementController(ProductService productService, PetService petService, AdoptionService adoptionService) {
        this.productService = productService;
        this.petService = petService;
        this.adoptionService = adoptionService;
    }

    @GetMapping("/products")
    public ResponseEntity<Page<Product>> getAllProducts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "updatedAt") String sortBy,
            @RequestParam(defaultValue = "DESC") Sort.Direction direction) {
        ensureAdmin();
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortBy));
        return new ResponseEntity<>(productService.getAllProducts(pageable), HttpStatus.OK);
    }

    @GetMapping("/products/{id}")
    public ResponseEntity<Product> getProduct(@PathVariable Long id) {
        ensureAdmin();
        return productService.getProductById(id)
                .map(product -> new ResponseEntity<>(product, HttpStatus.OK))
                .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
    }

    @PostMapping("/products")
    public ResponseEntity<Product> createProduct(@RequestBody Product product) {
        ensureAdmin();
        Product created = productService.createProduct(product);
        return new ResponseEntity<>(created, HttpStatus.CREATED);
    }

    @PutMapping("/products/{id}")
    public ResponseEntity<Product> updateProduct(@PathVariable Long id, @RequestBody Product productDetails) {
        ensureAdmin();
        try {
            return new ResponseEntity<>(productService.updateProduct(id, productDetails), HttpStatus.OK);
        } catch (RuntimeException ex) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    @DeleteMapping("/products/{id}")
    public ResponseEntity<Void> deleteProduct(@PathVariable Long id) {
        ensureAdmin();
        if (productService.getProductById(id).isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        productService.deleteProduct(id);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }

    @GetMapping("/pets")
    public ResponseEntity<List<Pet>> getAllPets() {
        ensureAdmin();
        return new ResponseEntity<>(petService.getAllPets(), HttpStatus.OK);
    }

    @GetMapping("/pets/{id}")
    public ResponseEntity<Pet> getPet(@PathVariable Long id) {
        ensureAdmin();
        return petService.getPetById(id)
                .map(pet -> new ResponseEntity<>(pet, HttpStatus.OK))
                .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
    }

    @PostMapping("/pets")
    public ResponseEntity<Pet> createPet(@RequestBody Pet pet) {
        ensureAdmin();
        Pet created = petService.createPet(pet);
        return new ResponseEntity<>(created, HttpStatus.CREATED);
    }

    @PutMapping("/pets/{id}")
    public ResponseEntity<Pet> updatePet(@PathVariable Long id, @RequestBody Pet petDetails) {
        ensureAdmin();
        try {
            return new ResponseEntity<>(petService.updatePet(id, petDetails), HttpStatus.OK);
        } catch (RuntimeException ex) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    @DeleteMapping("/pets/{id}")
    public ResponseEntity<Void> deletePet(@PathVariable Long id) {
        ensureAdmin();
        if (petService.getPetById(id).isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        petService.deletePet(id);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }

    @GetMapping("/adoptions/requests")
    public ResponseEntity<List<AdoptionRequest>> getAllAdoptionRequests() {
        ensureAdmin();
        return new ResponseEntity<>(adoptionService.getAllRequests(), HttpStatus.OK);
    }

    @GetMapping("/adoptions/requests/{id}")
    public ResponseEntity<AdoptionRequest> getAdoptionRequest(@PathVariable Long id) {
        ensureAdmin();
        return adoptionService.getRequest(id)
                .map(request -> new ResponseEntity<>(request, HttpStatus.OK))
                .orElseGet(() -> new ResponseEntity<>(HttpStatus.NOT_FOUND));
    }

    @GetMapping("/adoptions/pets/{petId}/requests")
    public ResponseEntity<List<AdoptionRequest>> getRequestsByPet(@PathVariable Long petId) {
        ensureAdmin();
        if (petService.getPetById(petId).isEmpty()) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
        return new ResponseEntity<>(adoptionService.getRequestsByPetId(petId), HttpStatus.OK);
    }

    @PutMapping("/adoptions/requests/{id}/status/{status}")
    public ResponseEntity<AdoptionRequest> updateAdoptionStatus(@PathVariable Long id, @PathVariable AdoptionRequest.Status status) {
        ensureAdmin();
        try {
            return new ResponseEntity<>(adoptionService.updateStatus(id, status), HttpStatus.OK);
        } catch (IllegalArgumentException ex) {
            return new ResponseEntity<>(HttpStatus.CONFLICT);
        } catch (RuntimeException ex) {
            return new ResponseEntity<>(HttpStatus.NOT_FOUND);
        }
    }

    private void ensureAdmin() {
        if (!SecurityUtil.isAdmin()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Admin access required");
        }
    }
}
