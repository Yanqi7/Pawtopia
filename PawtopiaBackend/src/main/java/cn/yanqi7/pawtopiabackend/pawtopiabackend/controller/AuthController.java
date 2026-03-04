package cn.yanqi7.pawtopiabackend.pawtopiabackend.controller;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.dto.AuthDtos;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.User;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.repository.UserRepository;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.security.JwtService;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.security.UserPrincipal;
import cn.yanqi7.pawtopiabackend.pawtopiabackend.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {
    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserService userService;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @PostMapping("/login")
    public ResponseEntity<AuthDtos.AuthResponse> login(@RequestBody AuthDtos.LoginRequest req) {
        Authentication auth = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(req.getUsername(), req.getPassword())
        );
        UserPrincipal principal = (UserPrincipal) auth.getPrincipal();
        User user = userRepository.findById(principal.getUserId()).orElseThrow();
        String token = jwtService.generate(principal);
        return new ResponseEntity<>(new AuthDtos.AuthResponse(token, user), HttpStatus.OK);
    }

    @PostMapping("/register")
    public ResponseEntity<AuthDtos.AuthResponse> register(@RequestBody AuthDtos.RegisterRequest req) {
        if (userRepository.existsByUsername(req.getUsername()) || userRepository.existsByEmail(req.getEmail())) {
            return new ResponseEntity<>(HttpStatus.CONFLICT);
        }
        User user = new User();
        user.setUsername(req.getUsername());
        user.setEmail(req.getEmail());
        user.setNickname(req.getNickname());
        user.setRole(req.getRole() == null ? User.Role.USER : req.getRole());
        user.setPassword(passwordEncoder.encode(req.getPassword()));
        User created = userService.createUser(user);

        UserPrincipal principal = new UserPrincipal(created.getId(), created.getUsername(), created.getPassword(), created.getRole());
        String token = jwtService.generate(principal);
        return new ResponseEntity<>(new AuthDtos.AuthResponse(token, created), HttpStatus.CREATED);
    }
}

