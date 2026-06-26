package com.auth.app.model;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// DTO regroupés dans un fichier pour simplicité

public class Dto {

    public record RegisterRequest(
        @NotBlank(message = "Le nom est obligatoire")
        String name,

        @NotBlank(message = "L'email est obligatoire")
        @Email(message = "Format email invalide")
        String email,

        @NotBlank(message = "Le mot de passe est obligatoire")
        @Size(min = 8, message = "Le mot de passe doit contenir au moins 8 caractères")
        String password
    ) {}

    public record LoginRequest(
        @NotBlank String email,
        @NotBlank String password
    ) {}

    public record UpdateRequest(
        String name,
        String password
    ) {}

    public record UserResponse(
        String id,
        String name,
        String email
    ) {}

    public record MessageResponse(String message) {}
}
