package com.auth.app.controller;

import com.auth.app.model.Dto.*;
import com.auth.app.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    @Value("${auth.mode:session}")
    private String authMode;

    // POST /api/auth/register
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest req) {
        try {
            UserResponse user = authService.register(req);
            return ResponseEntity.status(HttpStatus.CREATED).body(user);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(new MessageResponse(e.getMessage()));
        }
    }

    // POST /api/auth/login
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest req,
                                   HttpServletRequest request) {
        try {
            String token = authService.login(req);

            if ("jwt".equals(authMode)) {
                // Retourne le token dans le corps
                return ResponseEntity.ok(Map.of("token", token));
            } else {
                // Mode session : stocker l'email en session
                HttpSession session = request.getSession(true);
                session.setAttribute("userEmail", req.email());
                return ResponseEntity.ok(new MessageResponse("Connexion réussie."));
            }
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(new MessageResponse(e.getMessage()));
        }
    }

    // GET /api/auth/me
    @GetMapping("/me")
    public ResponseEntity<?> getMe(Authentication authentication,
                                   HttpServletRequest request) {
        try {
            String email = resolveEmail(authentication, request);
            if (email == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            return ResponseEntity.ok(authService.getMe(email));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(new MessageResponse(e.getMessage()));
        }
    }

    // PUT /api/auth/me
    @PutMapping("/me")
    public ResponseEntity<?> updateMe(@RequestBody UpdateRequest req,
                                      Authentication authentication,
                                      HttpServletRequest request) {
        try {
            String email = resolveEmail(authentication, request);
            if (email == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            return ResponseEntity.ok(authService.updateMe(email, req));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    // DELETE /api/auth/me
    @DeleteMapping("/me")
    public ResponseEntity<?> deleteMe(Authentication authentication,
                                      HttpServletRequest request) {
        try {
            String email = resolveEmail(authentication, request);
            if (email == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            authService.deleteMe(email);

            // Invalider la session si mode session
            if (!"jwt".equals(authMode)) {
                HttpSession session = request.getSession(false);
                if (session != null) session.invalidate();
            }

            return ResponseEntity.ok(new MessageResponse("Compte supprimé avec succès."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(new MessageResponse(e.getMessage()));
        }
    }

    // POST /api/auth/logout
    @PostMapping("/logout")
    public ResponseEntity<?> logout(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) session.invalidate();
        return ResponseEntity.ok(new MessageResponse("Déconnexion réussie."));
    }

    /**
     * Résout l'email de l'utilisateur courant selon le mode auth.
     * - JWT  : via l'Authentication renseignée par JwtFilter (principal = email)
     * - Session : via l'attribut "userEmail" stocké en session
     */
    private String resolveEmail(Authentication authentication, HttpServletRequest request) {
        if ("jwt".equals(authMode)) {
            return (authentication != null) ? (String) authentication.getPrincipal() : null;
        } else {
            HttpSession session = request.getSession(false);
            return (session != null) ? (String) session.getAttribute("userEmail") : null;
        }
    }
}
