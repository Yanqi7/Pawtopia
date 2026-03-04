package cn.yanqi7.pawtopiabackend.pawtopiabackend.security;

import cn.yanqi7.pawtopiabackend.pawtopiabackend.entity.User;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public class SecurityUtil {
    public static UserPrincipal principal() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            return null;
        }
        Object p = auth.getPrincipal();
        if (p instanceof UserPrincipal) {
            return (UserPrincipal) p;
        }
        return null;
    }

    public static Long userId() {
        UserPrincipal p = principal();
        return p == null ? null : p.getUserId();
    }

    public static User.Role role() {
        UserPrincipal p = principal();
        return p == null ? null : p.getRole();
    }

    public static boolean isAdmin() {
        User.Role r = role();
        return r == User.Role.ADMIN;
    }
}

