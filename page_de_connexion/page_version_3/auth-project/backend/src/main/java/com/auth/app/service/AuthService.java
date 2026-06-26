package com.auth.app.service;

import com.auth.app.model.Dto.*;
import com.auth.app.model.User;
import com.auth.app.repository.UserRepository;
import com.auth.app.security.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Value("${auth.mode:session}")
    private String authMode;

    public UserResponse register(RegisterRequest req) {
        if (userRepository.existsByEmail(req.email())) {
            throw new IllegalArgumentException("Un compte existe déjà avec cet email.");
        }
        User user = new User();
        user.setName(req.name());
        user.setEmail(req.email());
        user.setPassword(passwordEncoder.encode(req.password()));
        User saved = userRepository.save(user);
        return new UserResponse(saved.getId(), saved.getName(), saved.getEmail());
    }

    /**
     * Retourne null si mode session (l'auth est gérée côté contrôleur via session),
     * ou un token JWT si mode jwt.
     */
    public String login(LoginRequest req) {
        User user = userRepository.findByEmail(req.email())
                .orElseThrow(() -> new IllegalArgumentException("Email ou mot de passe incorrect."));
        if (!passwordEncoder.matches(req.password(), user.getPassword())) {
            throw new IllegalArgumentException("Email ou mot de passe incorrect.");
        }
        if ("jwt".equals(authMode)) {
            return jwtUtil.generateToken(user.getEmail());
        }
        return null; // la session est gérée dans le contrôleur
    }

    public UserResponse getMe(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur introuvable."));
        return new UserResponse(user.getId(), user.getName(), user.getEmail());
    }

    public UserResponse updateMe(String email, UpdateRequest req) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur introuvable."));
        if (req.name() != null && !req.name().isBlank()) {
            user.setName(req.name());
        }
        if (req.password() != null && !req.password().isBlank()) {
            if (req.password().length() < 8) {
                throw new IllegalArgumentException("Le mot de passe doit contenir au moins 8 caractères.");
            }
            user.setPassword(passwordEncoder.encode(req.password()));
        }
        User saved = userRepository.save(user);
        return new UserResponse(saved.getId(), saved.getName(), saved.getEmail());
    }

    public void deleteMe(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur introuvable."));
        userRepository.delete(user);
    }
}
