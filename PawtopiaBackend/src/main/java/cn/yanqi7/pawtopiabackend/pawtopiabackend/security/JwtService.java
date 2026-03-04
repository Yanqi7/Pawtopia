package cn.yanqi7.pawtopiabackend.pawtopiabackend.security;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;

@Service
public class JwtService {
    private final SecretKey key;
    private final long expMinutes;

    public JwtService(
            @Value("${app.jwt.secret}") String secret,
            @Value("${app.jwt.expMinutes:720}") long expMinutes
    ) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expMinutes = expMinutes;
    }

    public String generate(UserPrincipal principal) {
        Instant now = Instant.now();
        Instant exp = now.plus(expMinutes, ChronoUnit.MINUTES);
        return Jwts.builder()
                .subject(String.valueOf(principal.getUserId()))
                .claim("username", principal.getUsername())
                .claim("role", principal.getRole().name())
                .issuedAt(Date.from(now))
                .expiration(Date.from(exp))
                .signWith(key)
                .compact();
    }

    public Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public Long extractUserId(Claims claims) {
        String subject = claims.getSubject();
        return subject == null ? null : Long.valueOf(subject);
    }

    public User.Role extractRole(Claims claims) {
        Object role = claims.get("role");
        if (role == null) {
            return User.Role.USER;
        }
        return User.Role.valueOf(String.valueOf(role));
    }

    public String extractUsername(Claims claims) {
        Object username = claims.get("username");
        return username == null ? null : String.valueOf(username);
    }
}

